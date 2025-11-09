from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base, scoped_session
import os

# 支持环境变量配置，优先使用 Supabase PostgreSQL，否则使用 SQLite
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./data.db")

# 如果是 PostgreSQL，不需要 check_same_thread 参数
if DATABASE_URL.startswith("postgresql://") or DATABASE_URL.startswith("postgres://"):
    # PostgreSQL 连接
    engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=300)
else:
    # SQLite 连接（开发环境）
    engine = create_engine(
        DATABASE_URL, connect_args={"check_same_thread": False}
    )

SessionLocal = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=engine))

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
