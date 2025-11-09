from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base, scoped_session
from sqlalchemy.sql import func
from zoneinfo import ZoneInfo
import datetime
import os

# 支持环境变量配置，优先使用 Supabase PostgreSQL，否则使用 SQLite
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./data.db")
DB_TIMEZONE = os.getenv("DB_TIMEZONE", "Asia/Shanghai")  # 默认北京时区 (UTC+8)
IS_POSTGRES = DATABASE_URL.startswith("postgresql://") or DATABASE_URL.startswith("postgres://")

# 如果是 PostgreSQL，不需要 check_same_thread 参数
if IS_POSTGRES:
    # PostgreSQL 连接，设置时区为北京时区
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_recycle=300,
        connect_args={"options": f"-c timezone={DB_TIMEZONE}"},
    )
else:
    # SQLite 连接（开发环境）
    engine = create_engine(
        DATABASE_URL, connect_args={"check_same_thread": False}
    )

# 对 PostgreSQL 连接，进一步确保会话时区设置
if IS_POSTGRES:
    @event.listens_for(engine, "connect")
    def _set_timezone(dbapi_connection, connection_record):
        try:
            cursor = dbapi_connection.cursor()
            cursor.execute(f"SET TIME ZONE '{DB_TIMEZONE}'")
            cursor.close()
        except Exception:
            # 若驱动不支持该语句，静默跳过，仍由 connect_args 保底
            pass

SessionLocal = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=engine))

Base = declarative_base()

# 统一导出服务器端时间戳表达式（用于 TIMESTAMP 的 server_default / onupdate）
if IS_POSTGRES:
    # PostgreSQL 在连接层已设置会话时区
    SERVER_TIMESTAMP_DEFAULT = func.current_timestamp()
    SERVER_TIMESTAMP_ONUPDATE = func.current_timestamp()
else:
    # SQLite 不支持时区，使用 +8 小时偏移保证写入北京时间
    SERVER_TIMESTAMP_DEFAULT = func.datetime(func.current_timestamp(), "+8 hours")
    SERVER_TIMESTAMP_ONUPDATE = func.datetime(func.current_timestamp(), "+8 hours")


def now_bjt() -> datetime.datetime:
    """返回北京时间（Asia/Shanghai）的当前时间，用于 DateTime Python 级默认值。"""
    return datetime.datetime.now(ZoneInfo(DB_TIMEZONE))


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
