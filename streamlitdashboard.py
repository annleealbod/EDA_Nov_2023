import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv("the motherlode.csv")

# Assuming df is your dataframe

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

# Create scatter plot
fig, ax = plt.subplots(figsize=(15, 10))
sns.scatterplot(x='avg_shift_lead', y='fill_rate', data=filtered_df, ax=ax)
ax.set_title(f'{csa_filter} (Joined Prior to 2022Q3)')
ax.set_ylabel('Average Fill Rate')
ax.set_xlabel('Average Shift Lead Time')
ax.set_ylim(0, 1.01)  # Set y-axis limits

# Show the plot using Streamlit
st.pyplot(fig)