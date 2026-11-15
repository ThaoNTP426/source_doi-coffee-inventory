const sql = require('./sql');

const useSqlAuth = Boolean(process.env.DB_USER);

const config = useSqlAuth
    ? {
        // Azure SQL Database / SQL Server voi SQL Authentication (driver tedious)
        server: process.env.DB_SERVER,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        port: Number(process.env.DB_PORT) || 1433,
        // Azure SQL serverless co the dang tam dung, can ~1 phut de khoi dong lai
        connectionTimeout: 90000,
        requestTimeout: 60000,
        options: {
            encrypt: true,
            trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true'
        }
    }
    : {
        // May local voi Windows Authentication (msnodesqlv8)
        server: process.env.DB_SERVER,
        database: process.env.DB_NAME,

        // Chỉ định ODBC Driver đã cài trên máy
        driver: 'ODBC Driver 17 for SQL Server',

        options: {
            trustedConnection: true,
            trustServerCertificate: true
        }
    };

let currentPool = null;

// Ket noi lazy + tu thu lai: neu lan ket noi truoc that bai (DB dang tam dung,
// mang chap chon...) thi request sau se ket noi lai thay vi loi mai mai.
function getPool() {
    if (!currentPool) {
        currentPool = new sql.ConnectionPool(config)
            .connect()
            .then(pool => {
                console.log('Da ket noi SQL Server thanh cong!');
                pool.on('error', () => { currentPool = null; });
                return pool;
            })
            .catch(error => {
                console.log('Loi ket noi SQL Server:', error.message);
                currentPool = null;
                throw error;
            });
    }
    return currentPool;
}

// Giu nguyen cach dung `await poolPromise` trong cac route.
const poolPromise = {
    then: (onFulfilled, onRejected) => getPool().then(onFulfilled, onRejected),
    catch: (onRejected) => getPool().catch(onRejected)
};

// Ket noi som luc khoi dong, nhung khong de loi lam sap server.
getPool().catch(() => {});

module.exports = {
    sql,
    poolPromise
};
