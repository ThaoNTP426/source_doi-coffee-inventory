// Chon driver SQL Server theo moi truong:
//  - Co DB_USER (Azure SQL / SQL Authentication) -> 'mssql' (tedious, chay duoc tren Linux)
//  - Khong co DB_USER (may local, Windows Authentication) -> 'mssql/msnodesqlv8' (can ODBC Driver 17)
module.exports = process.env.DB_USER
    ? require('mssql')
    : require('mssql/msnodesqlv8');
