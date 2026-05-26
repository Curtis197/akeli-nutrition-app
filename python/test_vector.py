import os
os.environ["DATABASE_URL"] = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"

from engine.vectorization import compute_user_vector, compute_recipe_vector
from engine.database import upsert_user_vector, upsert_recipe_vector, get_conn

def test():
    user_id = 'f1414791-8f57-4bf4-a730-42f3c89dad95'
    
    # We need a recipe ID from the database
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM recipe LIMIT 1")
            recipe_id = cur.fetchone()[0]

    print(f"Testing User Vector for {user_id}...")
    user_vec = compute_user_vector(user_id)
    if user_vec is not None:
        print(f"Generated user vector of size {len(user_vec)}")
        print(f"Sample: {user_vec[:5]}")
        upsert_user_vector(user_id, user_vec)
        print("Upserted user vector!")
    else:
        print("Failed to generate user vector.")

    print(f"\nTesting Recipe Vector for {recipe_id}...")
    recipe_vec = compute_recipe_vector(recipe_id)
    if recipe_vec is not None:
        print(f"Generated recipe vector of size {len(recipe_vec)}")
        print(f"Sample: {recipe_vec[:5]}")
        upsert_recipe_vector(recipe_id, recipe_vec)
        print("Upserted recipe vector!")
    else:
        print("Failed to generate recipe vector.")

if __name__ == "__main__":
    test()
