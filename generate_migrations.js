const fs = require('fs');
const content = fs.readFileSync('C:\\Users\\DELL LATITUDE 7480\\.gemini\\antigravity\\brain\\5262432d-b6d1-4d12-bef2-ee418ec5a8e4\\.system_generated\\steps\\401\\output.txt', 'utf8');
const match = content.match(/<untrusted-data-[^>]+>\s*(.*?)\s*<\/untrusted-data-[^>]+>/s);
const data = JSON.parse(match[1]);
let sql = '-- Migration: Add missing foreign key indexes\n\n';
for (const row of data) {
    const idxName = 'idx_' + row.table_name.replace(/\./g, '_') + '_' + row.column_name;
    sql += `CREATE INDEX IF NOT EXISTS ${idxName} ON ${row.table_name} (${row.column_name});\n`;
}
fs.writeFileSync('supabase/migrations/20260616153500_add_missing_fk_indexes.sql', sql);
console.log('Done!');
