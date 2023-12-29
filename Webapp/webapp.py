import streamlit as st
import pandas as pd
import psycopg2


@st.cache_resource
def init_connection():
    return psycopg2.connect(**st.secrets["postgres"])

conn = init_connection()

def get_data(query):
    with conn.cursor() as cur:
        cur.execute(query)
        data = cur.fetchall()
        df = pd.DataFrame(data, columns=[desc[0] for desc in cur.description])
        return df

st.header("Farmer's Market Database")
st.write("Enter your query please:")

query = st.text_input("Query:")
if query:
    df = get_data(query)
    if not df.empty:
        st.dataframe(df)
    else:
        st.write("Data was not found.")

with conn.cursor() as cur:
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
    table_names = [name[0] for name in cur.fetchall()]


table_name = st.selectbox("Select your table:", table_names)
if table_name:
    st.write(f"Displaying data from table: {table_name}")
    query = f"SELECT * FROM {table_name}"
    df = get_data(query)
    if not df.empty:
        st.dataframe(df)
    else:
        st.write("No data found.")


