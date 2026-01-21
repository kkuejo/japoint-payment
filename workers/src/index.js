/**
 * JAPOINT Payment API - Cloudflare Workers
 *
 * Endpoints:
 * - POST /api/payments - Record a new payment
 * - GET /api/payments - Get payment history with filters
 * - GET /api/payments/summary - Get aggregated summary
 * - GET /api/payments/daily - Get daily breakdown
 */

const CORS_HEADERS = {
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
};

function getCorsHeaders(request, env) {
    const origin = request.headers.get('Origin') || '';
    const allowedOrigins = (env.ALLOWED_ORIGINS || '').split(',');

    // Allow localhost for development
    if (origin.includes('localhost') || origin.includes('127.0.0.1') || allowedOrigins.includes(origin)) {
        return {
            ...CORS_HEADERS,
            'Access-Control-Allow-Origin': origin,
        };
    }

    // Default to first allowed origin
    return {
        ...CORS_HEADERS,
        'Access-Control-Allow-Origin': allowedOrigins[0] || '*',
    };
}

function jsonResponse(data, status = 200, request, env) {
    return new Response(JSON.stringify(data), {
        status,
        headers: {
            'Content-Type': 'application/json',
            ...getCorsHeaders(request, env),
        },
    });
}

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);
        const path = url.pathname;

        // Handle CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, {
                headers: getCorsHeaders(request, env),
            });
        }

        try {
            // Route handling
            if (path === '/api/payments' && request.method === 'POST') {
                return await handleCreatePayment(request, env);
            }

            if (path === '/api/payments' && request.method === 'GET') {
                return await handleGetPayments(request, env);
            }

            if (path === '/api/payments/summary' && request.method === 'GET') {
                return await handleGetSummary(request, env);
            }

            if (path === '/api/payments/daily' && request.method === 'GET') {
                return await handleGetDailySummary(request, env);
            }

            if (path === '/api/health') {
                return jsonResponse({ status: 'ok', timestamp: new Date().toISOString() }, 200, request, env);
            }

            return jsonResponse({ error: 'Not Found' }, 404, request, env);

        } catch (error) {
            console.error('API Error:', error);
            return jsonResponse({ error: error.message }, 500, request, env);
        }
    },
};

/**
 * Record a new payment
 */
async function handleCreatePayment(request, env) {
    const data = await request.json();

    // Validate required fields
    const required = ['txHash', 'senderAddress', 'shopAddress', 'companyAddress',
                      'totalAmount', 'shopAmount', 'companyAmount', 'japtAmount',
                      'planType', 'blockNumber', 'blockTimestamp'];

    for (const field of required) {
        if (!data[field]) {
            return jsonResponse({ error: `Missing required field: ${field}` }, 400, request, env);
        }
    }

    // Insert payment record
    try {
        await env.DB.prepare(`
            INSERT INTO payments (
                tx_hash, sender_address, shop_address, company_address,
                total_amount, shop_amount, company_amount, japt_amount,
                plan_type, block_number, block_timestamp
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
            data.txHash,
            data.senderAddress.toLowerCase(),
            data.shopAddress.toLowerCase(),
            data.companyAddress.toLowerCase(),
            data.totalAmount,
            data.shopAmount,
            data.companyAmount,
            data.japtAmount,
            data.planType,
            data.blockNumber,
            data.blockTimestamp
        ).run();

        // Update daily summary
        const date = new Date(data.blockTimestamp * 1000).toISOString().split('T')[0];
        await updateDailySummary(env, date, data);

        return jsonResponse({ success: true, txHash: data.txHash }, 201, request, env);

    } catch (error) {
        // Handle duplicate tx_hash
        if (error.message.includes('UNIQUE constraint')) {
            return jsonResponse({ error: 'Payment already recorded', txHash: data.txHash }, 409, request, env);
        }
        throw error;
    }
}

/**
 * Get payment history with optional filters
 */
async function handleGetPayments(request, env) {
    const url = new URL(request.url);
    const params = url.searchParams;

    let query = 'SELECT * FROM payments WHERE 1=1';
    const bindings = [];

    // Filter by sender
    if (params.get('sender')) {
        query += ' AND sender_address = ?';
        bindings.push(params.get('sender').toLowerCase());
    }

    // Filter by shop
    if (params.get('shop')) {
        query += ' AND shop_address = ?';
        bindings.push(params.get('shop').toLowerCase());
    }

    // Filter by plan type
    if (params.get('planType')) {
        query += ' AND plan_type = ?';
        bindings.push(params.get('planType'));
    }

    // Filter by date range
    if (params.get('from')) {
        query += ' AND block_timestamp >= ?';
        bindings.push(Math.floor(new Date(params.get('from')).getTime() / 1000));
    }

    if (params.get('to')) {
        query += ' AND block_timestamp <= ?';
        bindings.push(Math.floor(new Date(params.get('to')).getTime() / 1000));
    }

    // Order and limit
    query += ' ORDER BY block_timestamp DESC';

    const limit = Math.min(parseInt(params.get('limit') || '100'), 1000);
    const offset = parseInt(params.get('offset') || '0');
    query += ` LIMIT ${limit} OFFSET ${offset}`;

    const stmt = env.DB.prepare(query);
    const result = await (bindings.length > 0 ? stmt.bind(...bindings) : stmt).all();

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as count FROM payments WHERE 1=1';
    const countBindings = [...bindings];

    if (params.get('sender')) {
        countQuery += ' AND sender_address = ?';
    }
    if (params.get('shop')) {
        countQuery += ' AND shop_address = ?';
    }
    if (params.get('planType')) {
        countQuery += ' AND plan_type = ?';
    }
    if (params.get('from')) {
        countQuery += ' AND block_timestamp >= ?';
    }
    if (params.get('to')) {
        countQuery += ' AND block_timestamp <= ?';
    }

    // Remove limit/offset bindings for count query
    const countStmt = env.DB.prepare(countQuery.replace(/ LIMIT \d+ OFFSET \d+/, ''));
    const countResult = await (countBindings.length > 0 ? countStmt.bind(...countBindings.slice(0, -2 < 0 ? countBindings.length : countBindings.length)) : countStmt).first();

    return jsonResponse({
        payments: result.results,
        pagination: {
            total: countResult?.count || 0,
            limit,
            offset,
        }
    }, 200, request, env);
}

/**
 * Get aggregated summary
 */
async function handleGetSummary(request, env) {
    const url = new URL(request.url);
    const params = url.searchParams;

    let whereClause = '1=1';
    const bindings = [];

    // Filter by date range
    if (params.get('from')) {
        whereClause += ' AND block_timestamp >= ?';
        bindings.push(Math.floor(new Date(params.get('from')).getTime() / 1000));
    }

    if (params.get('to')) {
        whereClause += ' AND block_timestamp <= ?';
        bindings.push(Math.floor(new Date(params.get('to')).getTime() / 1000));
    }

    // Get summary by plan type
    const query = `
        SELECT
            plan_type,
            COUNT(*) as transaction_count,
            SUM(CAST(total_amount AS REAL)) as total_jpyc,
            SUM(CAST(japt_amount AS REAL)) as total_japt,
            SUM(CAST(shop_amount AS REAL)) as total_shop_revenue,
            SUM(CAST(company_amount AS REAL)) as total_company_revenue
        FROM payments
        WHERE ${whereClause}
        GROUP BY plan_type
    `;

    const stmt = env.DB.prepare(query);
    const result = await (bindings.length > 0 ? stmt.bind(...bindings) : stmt).all();

    // Calculate totals
    const totals = {
        transactionCount: 0,
        totalJpyc: 0,
        totalJapt: 0,
        totalShopRevenue: 0,
        totalCompanyRevenue: 0,
    };

    const byPlanType = {};

    for (const row of result.results) {
        byPlanType[row.plan_type] = {
            transactionCount: row.transaction_count,
            totalJpyc: row.total_jpyc || 0,
            totalJapt: row.total_japt || 0,
            totalShopRevenue: row.total_shop_revenue || 0,
            totalCompanyRevenue: row.total_company_revenue || 0,
        };

        totals.transactionCount += row.transaction_count;
        totals.totalJpyc += row.total_jpyc || 0;
        totals.totalJapt += row.total_japt || 0;
        totals.totalShopRevenue += row.total_shop_revenue || 0;
        totals.totalCompanyRevenue += row.total_company_revenue || 0;
    }

    return jsonResponse({
        totals,
        byPlanType,
    }, 200, request, env);
}

/**
 * Get daily breakdown
 */
async function handleGetDailySummary(request, env) {
    const url = new URL(request.url);
    const params = url.searchParams;

    let query = 'SELECT * FROM daily_summary WHERE 1=1';
    const bindings = [];

    // Filter by date range
    if (params.get('from')) {
        query += ' AND date >= ?';
        bindings.push(params.get('from'));
    }

    if (params.get('to')) {
        query += ' AND date <= ?';
        bindings.push(params.get('to'));
    }

    // Filter by plan type
    if (params.get('planType')) {
        query += ' AND plan_type = ?';
        bindings.push(params.get('planType'));
    }

    query += ' ORDER BY date DESC LIMIT 365';

    const stmt = env.DB.prepare(query);
    const result = await (bindings.length > 0 ? stmt.bind(...bindings) : stmt).all();

    return jsonResponse({
        dailySummary: result.results,
    }, 200, request, env);
}

/**
 * Update daily summary
 */
async function updateDailySummary(env, date, paymentData) {
    // Try to update existing record
    const existing = await env.DB.prepare(
        'SELECT * FROM daily_summary WHERE date = ? AND plan_type = ?'
    ).bind(date, paymentData.planType).first();

    if (existing) {
        await env.DB.prepare(`
            UPDATE daily_summary SET
                total_transactions = total_transactions + 1,
                total_jpyc = CAST(CAST(total_jpyc AS REAL) + ? AS TEXT),
                total_japt = CAST(CAST(total_japt AS REAL) + ? AS TEXT),
                total_shop_revenue = CAST(CAST(total_shop_revenue AS REAL) + ? AS TEXT),
                total_company_revenue = CAST(CAST(total_company_revenue AS REAL) + ? AS TEXT)
            WHERE date = ? AND plan_type = ?
        `).bind(
            parseFloat(paymentData.totalAmount),
            parseFloat(paymentData.japtAmount),
            parseFloat(paymentData.shopAmount),
            parseFloat(paymentData.companyAmount),
            date,
            paymentData.planType
        ).run();
    } else {
        await env.DB.prepare(`
            INSERT INTO daily_summary (date, plan_type, total_transactions, total_jpyc, total_japt, total_shop_revenue, total_company_revenue)
            VALUES (?, ?, 1, ?, ?, ?, ?)
        `).bind(
            date,
            paymentData.planType,
            paymentData.totalAmount,
            paymentData.japtAmount,
            paymentData.shopAmount,
            paymentData.companyAmount
        ).run();
    }
}
