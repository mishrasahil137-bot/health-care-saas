require('dotenv').config();
const fs = require('fs'); const path = require('path'); const db = require('./db');
(async()=>{ try { const sql=fs.readFileSync(path.join(__dirname,'../db/schema.sql'),'utf8'); await db.query(sql); console.log('Database schema applied.'); } catch(e){ console.error(e); process.exitCode=1; } finally { await db.pool.end(); } })();
