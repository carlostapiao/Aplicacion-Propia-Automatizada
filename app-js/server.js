const express = require('express');
const sql = require('mssql');
const path = require('path'); // Añadido para manejar rutas de archivos
const app = express();

app.use(express.json());

// 1. CONFIGURACIÓN: Permitir que /tickets y /tickets/ funcionen igual
app.set('strict routing', false);

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true,
        trustServerCertificate: true
    }
};

// 2. RUTAS DE API (Deben ir ANTES de express.static)
app.get('/tickets', async (req, res) => {
    try {
        let pool = await sql.connect(dbConfig);
        let result = await pool.request().query('SELECT * FROM Tickets');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send('Error en la base de datos: ' + err.message);
    }
});

app.post('/tickets', async (req, res) => {
    try {
        const { titulo, descripcion } = req.body;
        let pool = await sql.connect(dbConfig);
        await pool.request()
            .input('titulo', sql.VarChar, titulo)
            .input('descripcion', sql.VarChar, descripcion)
            .query('INSERT INTO Tickets (titulo, descripcion) VALUES (@titulo, @descripcion)');
        res.status(201).json({ mensaje: 'Ticket creado con éxito' });
    } catch (err) {
        res.status(500).send('Error al crear ticket: ' + err.message);
    }
});

// 3. ARCHIVOS ESTÁTICOS Y RUTA RAÍZ (Al final para no pisar la API)
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
    res.send('Servidor IT funcionando correctamente v3');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor IT en puerto ${PORT}`);
    sql.connect(dbConfig)
        .then(() => console.log('Conectado a Azure SQL con éxito'))
        .catch(err => console.log('Error inicial de conexión SQL:', err));
});