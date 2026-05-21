tldr extract backend/db.py | jq -r '.functions[] | select(.name=="is_sqlite_lock_error") | .line' | xargs -I {} tldr slice backend/db.py is_sqlite_lock_error {}
