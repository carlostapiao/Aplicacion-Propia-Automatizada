const express = require('express');
const sql = require('mssql');
const app = express();

app.use(express.json());

// Configuración de la base de datos (Usando las variables del deploy.yaml)
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

// Ruta Raíz (Para verificar que el pod responde)
app.get('/', (req, res) => {
    res.send('Servidor IT funcionando correctamente v3');
});

// RUTA GET: Listar Tickets (La que pide el APIM)
app.get('/tickets', async (req, res) => {
    try {
        let pool = await sql.connect(dbConfig);
        let result = await pool.request().query('SELECT * FROM Tickets');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send('Error en la base de datos: ' + err.message);
    }
});

// RUTA POST: Crear Ticket (La que pide el APIM)
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor IT en puerto ${PORT}`);
    sql.connect(dbConfig).then(() => console.log('Conectado a Azure SQL con éxito'));
});