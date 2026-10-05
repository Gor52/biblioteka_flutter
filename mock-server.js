const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
    const delay = req.query.__delay ? parseInt(req.query.__delay) : 0;

    if (req.query.__fail) {
        return setTimeout(() => res.status(parseInt(req.query.__fail)).json({ 
            message: 'Искусственная ошибка сервера для проверки' 
        }), delay);
    }

    if (req.method === 'POST' && req.path === '/api/books') {
        if (req.body.isbn === '0000000000') {
            return setTimeout(() => res.status(422).json({
                message: 'Ошибка валидации',
                errors: { isbn: 'Книга с таким ISBN уже существует в базе' }
            }), delay);
        }
    }

    if (req.method === 'POST' && req.path === '/api/genres/bulk-hard-delete') {
        if (req.body.ids && req.body.ids.includes(1)) {
            return setTimeout(() => res.status(409).json({
                message: 'Невозможно удалить жанр: к нему привязаны существующие книги.'
            }), delay);
        }
    }

    if (delay > 0) return setTimeout(next, delay);
    next();
});

let db = {
    genres: [
        { id: 1, name: 'Фантастика', isDeleted: false },
        { id: 2, name: 'Научная литература', isDeleted: false },
        { id: 3, name: 'Детектив', isDeleted: false }
    ],
    publishers: [
        { id: 1, name: 'Эксмо', city: 'Москва', isDeleted: false },
        { id: 2, name: 'АСТ', city: 'Москва', isDeleted: false }
    ],
    authors: [
        { id: 1, lastName: 'Оруэлл', firstName: 'Джордж', country: 'Великобритания', birthYear: 1903, isDeleted: false }
    ],
    books: [
        { id: 1, title: '1984', isbn: '978-5-17', year: 1949, pages: 328, copiesTotal: 5, publisherId: 2, authorIds: [1], genreIds: [1], isDeleted: false }
    ],
    readers: [
        { id: 1, fullName: 'Иванов Иван', email: 'ivan@test.ru', phone: '12345', card: { cardNumber: '001', isActive: true, issuedAt: new Date().toISOString() }, isDeleted: false }
    ]
};

let nextId = 100; 

Object.keys(db).forEach(collection => {
    const path = `/api/${collection}`;

    app.get(path, (req, res) => {
        const showDeleted = req.query.deleted === 'true';
        const search = req.query.search ? req.query.search.toLowerCase() : '';
        const sortParam = req.query.sort; 
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;

        let items = [...db[collection]]; 

        if (!showDeleted) {
            items = items.filter(item => !item.isDeleted);
        }

        const genreId = req.query.genre || req.query.genreId;
        if (genreId) {
            items = items.filter(item => item.genreIds && item.genreIds.includes(parseInt(genreId)));
        }

        const pubId = req.query.pub || req.query.publisherId;
        if (pubId) {
            items = items.filter(item => item.publisherId === parseInt(pubId));
        }

        if (search) {
            items = items.filter(item => {
                return Object.values(item).some(val => 
                    val !== null && val !== undefined && 
                    String(val).toLowerCase().includes(search)
                );
            });
        }

        if (sortParam) {
            const parts = sortParam.split(',');
            const sortKey = parts[0];
            const isAsc = parts[1] !== 'desc'; 
            
            items.sort((a, b) => {
                let valA = a[sortKey] ?? '';
                let valB = b[sortKey] ?? '';
                
                if (typeof valA === 'string' && typeof valB === 'string') {
                    return isAsc ? valA.localeCompare(valB) : valB.localeCompare(valA);
                }
                return isAsc ? (valA > valB ? 1 : -1) : (valA < valB ? 1 : -1);
            });
        }

        const total = items.length;
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + limit;
        const paginatedItems = items.slice(startIndex, endIndex);

        res.json({
            items: paginatedItems,
            page: page,
            limit: limit,
            total: total
        });
    });

    app.get(`${path}/:id`, (req, res) => {
        const item = db[collection].find(i => i.id === parseInt(req.params.id));
        item ? res.json(item) : res.status(404).json({ error: 'Not found' });
    });

    app.post(path, (req, res) => {
        const newItem = { id: nextId++, ...req.body, isDeleted: false };
        db[collection].push(newItem);
        res.json(newItem);
    });

    app.put(`${path}/:id`, (req, res) => {
        const idx = db[collection].findIndex(i => i.id === parseInt(req.params.id));
        if (idx > -1) {
            db[collection][idx] = { ...db[collection][idx], ...req.body };
            res.json(db[collection][idx]);
        } else {
            res.status(404).json({ error: 'Not found' });
        }
    });

    app.post(`${path}/bulk-soft-delete`, (req, res) => {
        const ids = req.body.ids || [];
        db[collection].forEach(item => { if (ids.includes(item.id)) item.isDeleted = true; });
        res.json({ success: true });
    });

    app.post(`${path}/bulk-restore`, (req, res) => {
        const ids = req.body.ids || [];
        db[collection].forEach(item => { if (ids.includes(item.id)) item.isDeleted = false; });
        res.json({ success: true });
    });

    app.post(`${path}/bulk-hard-delete`, (req, res) => {
        const ids = req.body.ids || [];
        db[collection] = db[collection].filter(item => !ids.includes(item.id));
        res.json({ success: true });
    });
});

app.use('/api', (req, res) => {
    res.json({ success: true, message: 'Успешно (mock fallback)' });
});

const PORT = 8080;
app.listen(PORT, () => {
    console.log(`Итоговый Mock-сервер запущен на порту ${PORT}`);
    console.log(`Поддерживается: CRUD, пагинация, поиск, сортировка, фильтры и имитация ошибок!`);
});