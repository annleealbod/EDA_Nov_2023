import streamlit as st
import pandas as pd

df = pd.read_csv("scrambled_motherlode.csv")


# Joined Prior to 2022Q3
filtered_df = df[(df['year_quarter_comp_start'] < '2022Q3') & (df['csa_name_mod2'].isin(['Salt Lake City-Provo-Orem, UT', 'Dallas-Fort Worth, TX-OK', 'Las Vegas-Henderson, NV', 'All Other Markets Combined']))]

# Streamlit app
st.title('(Joined Prior to 2022Q3) Average Shift Lead Time vs Average Fill Rate by CSA Name')

# Add filters
csa_filter = st.selectbox('Select CSA Name', filtered_df['csa_name_mod2'].unique())
fill_rate_threshold = st.slider('Select Fill Rate Threshold', 0.0, 1.0, 0.5)
lead_time_threshold = st.slider('Select Average Shift Lead Time Threshold', 0, 50, 25)

# Filter data based on user input
filtered_df = filtered_df[(filtered_df['csa_name_mod2'] == csa_filter) &
                          (filtered_df['fill_rate'] >= fill_rate_threshold) &
                          (filtered_df['avg_shift_lead'] <= lead_time_threshold)]

# Create scatter plot using Plotly
fig = px.scatter(filtered_df, x='avg_shift_lead', y='fill_rate', title=f'{csa_filter} (Joined Prior to 2022Q3)',
                 labels={'avg_shift_lead': 'Average Shift Lead Time', 'fill_rate': 'Average Fill Rate'})

# Set y-axis limits
fig.update_yaxes(range=[0, 1.01])

# Show the plot using Streamlit
st.plotly_chart(fig)
