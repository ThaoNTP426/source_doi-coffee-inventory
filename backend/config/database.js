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

const poolPromise = new sql.ConnectionPool(config)
    .connect()
    .then(pool => {
        console.log('Da ket noi SQL Server thanh cong!');
        return pool;
    })
    .catch(error => {
        console.log('Loi ket noi SQL Server:', error.message);
        throw error;
    });

// Khong de loi ket noi DB lam sap ca server luc khoi dong (unhandled rejection).
// Cac route van nhan loi khi await poolPromise.
poolPromise.catch(() => {});

module.exports = {
    sql,
    poolPromise
};
