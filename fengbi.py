import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp
import networkx as nx
import pandas as pd
import seaborn as sns

# Define major Chinese cities
cities = ['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Chengdu', 'Wuhan', 'Harbin']
n_cities = len(cities)

# City parameters
population = np.array([2154, 2501, 1870, 1768, 2093, 1330, 1050]) * 10000  # Population in 10,000s
vaccine_rate = np.array([0.85, 0.87, 0.82, 0.83, 0.80, 0.81, 0.78])  # Vaccination rate
temperature = np.array([-3, 5, 14, 16, 8, 5, -20])  # Average winter temperature (°C)

# Create inter-city mobility network with no connections (isolated cities)
G = nx.DiGraph()
for i in range(n_cities):
    G.add_node(i, population=population[i], vaccine_rate=vaccine_rate[i], temperature=temperature[i])

# No connections between cities (all cities are isolated)
connections = []  # Empty list for no connections

for i, j, w in connections:
    G.add_edge(i, j, weight=w)

# Temperature-dependent virus survival factor
def virus_survival_factor(temp):
    return 1 + 0.02 * max(0, 10 - temp)  # Higher survival at lower temps

# Vaccine-adjusted susceptibility
def susceptibility_factor(vax_rate):
    return 1 - 0.5 * vax_rate  # Higher vax -> lower susceptibility

# SEIRS parameters
sigma = 1/5.0    # E->I rate (incubation period)
gamma = 1/14.0   # I->R rate (recovery period)
xi = 1/180.0     # R->S rate (waning immunity)

# Base reproduction number
base_R0 = 5.0  # Omicron variant

def get_beta(city_idx):
    temp = G.nodes[city_idx]['temperature']
    vax = G.nodes[city_idx]['vaccine_rate']
    policy_factor = 0.7  # Stricter policy multiplier for isolated cities
    return base_R0 * gamma * virus_survival_factor(temp) * susceptibility_factor(vax) * policy_factor

def get_initial_conditions():
    y0 = np.zeros(4 * n_cities)
    initial_infected_ratio = np.array([0.001, 0.0012, 0.0015, 0.0014, 0.0009, 0.001, 0.0008])
    
    for i in range(n_cities):
        pop = population[i]
        infected = pop * initial_infected_ratio[i]
        exposed = infected * 1.5  # 1.5x exposed vs infected
        recovered = pop * 0.1     # 10% pre-existing immunity
        susceptible = pop - exposed - infected - recovered
        
        y0[i] = susceptible
        y0[i + n_cities] = exposed
        y0[i + 2*n_cities] = infected
        y0[i + 3*n_cities] = recovered
    
    return y0

def seirs_model(t, y):
    dydt = np.zeros(4 * n_cities)

    # Calculate epidemiological changes for each isolated city
    for i in range(n_cities):
        N = population[i]
        beta = get_beta(i)
        
        S = y[i]
        E = y[i + n_cities]
        I = y[i + 2*n_cities]
        R = y[i + 3*n_cities]
        
        infection = beta * S * I / N
        
        dydt[i] = xi * R - infection
        dydt[i + n_cities] = infection - sigma * E
        dydt[i + 2*n_cities] = sigma * E - gamma * I
        dydt[i + 3*n_cities] = gamma * I - xi * R
    
    return dydt

# Simulation parameters
days = 180
t_span = (0, days)
t_eval = np.arange(0, days+1, 1)

# Solve ODE
y0 = get_initial_conditions()
solution = solve_ivp(seirs_model, t_span, y0, t_eval=t_eval, method='RK45')
t = solution.t
y = solution.y

# Visualization
plt.figure(figsize=(20, 15))

for i, city in enumerate(cities):
    plt.subplot(3, 3, i+1)
    
    S = y[i]
    E = y[i + n_cities]
    I = y[i + 2*n_cities]
    R = y[i + 3*n_cities]
    N = population[i]
    
    plt.plot(t, S/N, 'b-', label='Susceptible')
    plt.plot(t, E/N, 'y-', label='Exposed')
    plt.plot(t, I/N, 'r-', label='Infected')
    plt.plot(t, R/N, 'g-', label='Recovered')
    
    plt.title(f'{city} (Pop: {population[i]/10000:.0f}0k, Vax: {vaccine_rate[i]:.0%}, Temp: {temperature[i]}°C)')
    plt.xlabel('Days')
    plt.ylabel('Population Ratio')
    plt.grid(True)
    plt.legend()
    plt.ylim(0, 1)

# Model parameters legend
plt.subplot(3, 3, n_cities+1)
plt.axis('off')
info_text = (
    f"Model Parameters:\n"
    f"Incubation Period: {1/sigma:.1f} days\n"
    f"Infectious Period: {1/gamma:.1f} days\n"
    f"Immunity Duration: {1/xi:.1f} days\n"
    f"Base R0: {base_R0}\n"
    f"Simulation Duration: {days} days\n"
    f"Assumptions: Winter conditions, Cities isolated"
)
plt.text(0.1, 0.5, info_text, fontsize=12)

# Peak analysis
peak_days = []
peak_infections = []

plt.subplot(3, 3, n_cities+2)
for i, city in enumerate(cities):
    I = y[i + 2*n_cities]
    N = population[i]
    peak_day = np.argmax(I)
    peak_infection = np.max(I) / N
    peak_days.append(peak_day)
    peak_infections.append(peak_infection)
    
    print(f"{city}: Infection peak at day {peak_day}, rate {peak_infection:.2%}")

# Create analysis dataframe
df_peaks = pd.DataFrame({
    'City': cities,
    'Peak Day': peak_days,
    'Peak Rate': peak_infections,
    'Population (10k)': population/10000,
    'Temperature (°C)': temperature,
    'Vaccination Rate': vaccine_rate
})

# Create multivariate plot
sns.scatterplot(
    data=df_peaks,
    x='Temperature (°C)',
    y='Peak Rate',
    size='Population (10k)',
    hue='Vaccination Rate',
    sizes=(50, 300),
    alpha=0.7
)
for i, row in df_peaks.iterrows():
    plt.annotate(row['City'], (row['Temperature (°C)'], row['Peak Rate']))
plt.title('Infection Dynamics in Isolated Cities: Temperature vs Vaccination vs Population')
plt.grid(True)

plt.tight_layout()
plt.savefig('covid_seirs_simulation_isolated.png', dpi=300)
plt.show()
