const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// 1. БАЗЫ ДАННЫХ (Перенесены вверх, чтобы быть доступными для всех маршрутов)
const users = [
    { id: 1, username: 'reader', password: 'reader123', fullName: 'Иванов Иван', email: 'ivan@test.ru', role: 'reader', readerId: 1 },
    { id: 2, username: 'librarian', password: 'librarian123', fullName: 'Анна Библиотекарь', email: 'lib@test.com', role: 'librarian', readerId: null },
    { id: 3, username: 'admin', password: 'admin123', fullName: 'Главный Админ', email: 'admin@test.com', role: 'admin', readerId: null }
];

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
        { 
            id: 1, 
            userId: 1, 
            fullName: 'Иванов Иван', 
            email: 'ivan@test.ru', 
            phone: '+7 (999) 123-45-67', 
            address: 'г. Москва, ул. Пушкина, д. 10, кв. 5',
            birthDate: '1990-05-15',
            card: { cardNumber: 'LIB-0001', isActive: true, issuedAt: '2023-01-15T10:00:00.000Z' }, 
            isDeleted: false 
        },
        { 
            id: 2, 
            userId: null, 
            fullName: 'Петров Петр', 
            email: 'petr@test.ru', 
            phone: '+7 (999) 765-43-21', 
            address: 'г. Москва, ул. Лермонтова, д. 2', 
            birthDate: '1985-11-20',
            card: { cardNumber: 'LIB-0002', isActive: true, issuedAt: '2023-02-20T11:30:00.000Z' }, 
            isDeleted: false 
        }
    ],
    loans: [] 
};

// 2. MIDDLEWARE (Искусственные ошибки)
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

// 3. МАРШРУТЫ АВТОРИЗАЦИИ
app.post('/api/auth/login', (req, res) => {
    const { username, password } = req.body;
    const user = users.find(u => u.username === username && u.password === password);
    
    if (!user) {
        return res.status(401).json({ message: 'Неверный логин или пароль' });
    }

    const token = `access_token_for_${user.username}`;
    const { password: _, ...safeUser } = user;

    res.json({
        accessToken: token,
        refreshToken: `refresh_token_for_${user.username}`,
        expiresIn: 43200,
        user: safeUser
    });
});

app.post('/api/auth/register', (req, res) => {
    const { username, password, fullName } = req.body;
    
    if (users.find(u => u.username === username)) {
        return res.status(409).json({ message: 'Пользователь с таким логином уже существует' });
    }

    const newUserId = users.length ? Math.max(...users.map(u => u.id)) + 1 : 1;
    const newReaderId = db.readers.length ? Math.max(...db.readers.map(r => r.id)) + 1 : 1;

    const newReader = {
        id: newReaderId,
        userId: newUserId,
        fullName: fullName,
        email: `${username}@test.com`,
        phone: '',
        address: '',
        birthDate: '',
        card: { cardNumber: `LIB-${String(newReaderId).padStart(4, '0')}`, isActive: true, issuedAt: new Date().toISOString() },
        isDeleted: false
    };
    db.readers.push(newReader);

    const newUser = {
        id: newUserId,
        username,
        password,
        fullName,
        email: `${username}@test.com`,
        role: 'reader',
        readerId: newReaderId
    };
    users.push(newUser);

    const token = `access_token_for_${newUser.username}`;
    const { password: _, ...safeUser } = newUser;

    res.json({
        accessToken: token,
        refreshToken: `refresh_token_for_${newUser.username}`,
        expiresIn: 43200,
        user: safeUser
    });
});

app.get('/api/auth/me', (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'Нет токена авторизации' });
    }

    const token = authHeader.split(' ')[1];
    const username = token.replace('access_token_for_', '');
    
    const user = users.find(u => u.username === username);
    if (!user) {
        return res.status(401).json({ message: 'Пользователь не найден' });
    }

    const { password: _, ...safeUser } = user;
    res.json(safeUser);
});

app.post('/api/auth/refresh', (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken || !refreshToken.startsWith('refresh_token_for_')) {
        return res.status(401).json({ message: 'Недействительный токен обновления' });
    }

    const username = refreshToken.replace('refresh_token_for_', '');
    const user = users.find(u => u.username === username);
    
    if (!user) {
        return res.status(401).json({ message: 'Пользователь не найден' });
    }

    const { password: _, ...safeUser } = user;
    res.json({
        accessToken: `access_token_for_${user.username}_refreshed`,
        refreshToken: `refresh_token_for_${user.username}_refreshed`,
        expiresIn: 43200,
        user: safeUser
    });
});

app.post('/api/auth/logout', (req, res) => {
    res.json({ success: true });
});

app.use('/api', (req, res, next) => {
    if (req.path.startsWith('/auth')) return next();

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'Нет токена авторизации' });
    }

    const username = authHeader.split(' ')[1].replace('access_token_for_', '');
    const user = users.find(u => u.username === username);
    
    if (!user) return res.status(401).json({ message: 'Недействительный токен' });

    if (req.path.startsWith('/users') || req.path.includes('bulk-hard-delete') || req.path.includes('bulk-restore')) {
        if (user.role !== 'admin') {
            return res.status(403).json({ message: 'Отказ: Требуются права администратора' });
        }
    } 
    else if (['POST', 'PUT', 'DELETE'].includes(req.method) && !req.path.startsWith('/loans')) {
        if (user.role !== 'librarian') {
            return res.status(403).json({ message: 'Отказ: Изменять каталоги может только библиотекарь' });
        }
    }

    next(); 
});


app.get('/api/users', (req, res) => {
    const safeUsers = users.map(({ password, ...u }) => u);
    res.json({ items: safeUsers, total: safeUsers.length });
});

app.put('/api/users/:id/role', (req, res) => {
    const userId = parseInt(req.params.id);
    const { role: newRole } = req.body;
    
    const userIndex = users.findIndex(u => u.id === userId);
    if (userIndex === -1) return res.status(404).json({ message: 'Пользователь не найден' });

    const user = users[userIndex];
    const oldRole = user.role;
    user.role = newRole;

    if (oldRole === 'reader' && newRole !== 'reader') {
        db.readers = db.readers.filter(r => r.userId !== userId);
        user.readerId = null;
    } else if (oldRole !== 'reader' && newRole === 'reader') {
        if (!user.readerId) {
            const newReaderId = db.readers.length ? Math.max(...db.readers.map(r => r.id)) + 1 : 1;
            db.readers.push({
                id: newReaderId, userId: userId, fullName: user.fullName, email: user.email,
                phone: '', address: '', birthDate: '',
                card: { cardNumber: `LIB-${String(newReaderId).padStart(4, '0')}`, isActive: true, issuedAt: new Date().toISOString() },
                isDeleted: false
            });
            user.readerId = newReaderId;
        }
    }

    const { password, ...safeUser } = user;
    res.json(safeUser);
});

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

        if (collection === 'authors' && db.books.some(b => !b.isDeleted && b.authorIds && b.authorIds.some(id => ids.includes(id)))) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить автора. К нему привязаны существующие книги.' });
        }
        if (collection === 'publishers' && db.books.some(b => !b.isDeleted && ids.includes(b.publisherId))) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить издательство. К нему привязаны существующие книги.' });
        }
        if (collection === 'genres' && db.books.some(b => !b.isDeleted && b.genreIds && b.genreIds.some(id => ids.includes(id)))) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить жанр. К нему привязаны существующие книги.' });
        }
        if (collection === 'readers' && db.loans.some(l => ids.includes(l.readerId) && !l.isReturned)) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить читателя. У него есть активные выдачи.' });
        }

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

        if (collection === 'authors' && db.books.some(b => b.authorIds && b.authorIds.some(id => ids.includes(id)))) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить автора. К нему привязаны книги.' });
        }
        if (collection === 'publishers' && db.books.some(b => ids.includes(b.publisherId))) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить издательство. К нему привязаны книги.' });
        }
        if (collection === 'genres' && db.books.some(b => b.genreIds && b.genreIds.some(id => ids.includes(id)))) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить жанр. К нему привязаны книги.' });
        }
        if (collection === 'readers' && db.loans.some(l => ids.includes(l.readerId) && !l.isReturned)) {
            return res.status(409).json({ message: 'Ошибка: Невозможно удалить читателя. У него есть активные выдачи.' });
        }

        db[collection] = db[collection].filter(item => !ids.includes(item.id));
        res.json({ success: true });
    });
});

app.use('/api', (req, res) => {
    res.json({ success: true, message: 'Успешно (mock fallback)' });
});

const PORT = 8080;
app.listen(PORT, () => {
    console.log(`Итоговый Mock-сервер с расширенными читателями запущен на порту ${PORT}`);
});