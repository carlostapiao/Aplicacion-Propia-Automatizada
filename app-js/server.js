const express = require('express');
const app = express();
app.use(express.json());

// RUTA DE PRUEBA (Para saber si el pod está vivo)
app.get('/', (req, res) => {
    res.send('API de Tickets v3 funcionando!');
});

// RUTA GET: Listar tickets
app.get('/tickets', (req, res) => {
    // Aquí va tu lógica de SQL
    res.status(200).json({ message: "Lista de tickets obtenida" });
});

// RUTA POST: Crear ticket
app.post('/tickets', (req, res) => {
    // Aquí va tu lógica de SQL
    res.status(201).json({ message: "Ticket creado con éxito" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor corriendo en puerto ${PORT}`);
});