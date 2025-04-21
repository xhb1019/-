import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp
import networkx as nx
import pandas as pd
import seaborn as sns

# 定义主要中国城市
cities = ['北京', '上海', '广州', '深圳', '成都', '武汉', '哈尔滨']
n_cities = len(cities)

# 城市基本参数
population = np.array([2154, 2501, 1870, 1768, 2093, 1330, 1050]) * 10000  # 各城市人口(万人)
vaccine_rate = np.array([0.85, 0.87, 0.82, 0.83, 0.80, 0.81, 0.78])  # 疫苗接种率
temperature = np.array([-3, 5, 14, 16, 8, 5, -20])  # 冬季平均温度(°C)

# 构建城市间流动网络(简化模型，实际应使用真实交通数据)
G = nx.DiGraph()
for i in range(n_cities):
    G.add_node(i, population=population[i], vaccine_rate=vaccine_rate[i], temperature=temperature[i])

# 添加城市间连接，权重代表人口流动强度
connections = [
    (0, 1, 0.003), (1, 0, 0.003),  # 北京-上海
    (0, 2, 0.002), (2, 0, 0.002),  # 北京-广州
    (0, 5, 0.002), (5, 0, 0.002),  # 北京-武汉
    (1, 2, 0.003), (2, 1, 0.003),  # 上海-广州
    (2, 3, 0.006), (3, 2, 0.006),  # 广州-深圳
    (4, 5, 0.003), (5, 4, 0.003),  # 成都-武汉
    (0, 6, 0.001), (6, 0, 0.001),  # 北京-哈尔滨
    (5, 1, 0.002), (1, 5, 0.002),  # 武汉-上海
    (5, 2, 0.002), (2, 5, 0.002),  # 武汉-广州
]

for i, j, w in connections:
    G.add_edge(i, j, weight=w)

# 根据温度调整病毒存活系数
def virus_survival_factor(temp):
    # 温度越低，病毒存活时间越长，传染性越强
    return 1 + 0.02 * max(0, 10 - temp)

# 根据疫苗率调整易感性
def susceptibility_factor(vax_rate):
    # 疫苗接种率越高，总体易感性越低
    return 1 - 0.5 * vax_rate

# SEIRS模型参数
sigma = 1/5.0    # 潜伏期相关的转化率 (E->I)
gamma = 1/14.0   # 康复率 (I->R)
xi = 1/180.0     # 免疫力丧失率 (R->S)

# 基本再生数R0(无干预情况)
base_R0 = 5.0  # 奥密克戎变异株的基本再生数

# 调整后的β将随城市而变化
def get_beta(city_idx):
    temp = G.nodes[city_idx]['temperature']
    vax = G.nodes[city_idx]['vaccine_rate']
    
    # 开放政策下的接触率增加因子
    open_policy_factor = 1.3
    
    # 结合温度和疫苗接种的影响
    beta = base_R0 * gamma * virus_survival_factor(temp) * susceptibility_factor(vax) * open_policy_factor
    return beta

# 初始条件：各城市的SEIRS初始值
def get_initial_conditions():
    y0 = np.zeros(4 * n_cities)
    
    # 初始感染者比例(各城市略有不同)
    initial_infected_ratio = np.array([0.001, 0.0012, 0.0015, 0.0014, 0.0009, 0.001, 0.0008])
    
    for i in range(n_cities):
        pop = population[i]
        infected = pop * initial_infected_ratio[i]
        exposed = infected * 1.5  # 假设潜伏期人数是感染者的1.5倍
        recovered = pop * 0.1     # 假设10%的人口已康复(前期感染)
        susceptible = pop - exposed - infected - recovered
        
        y0[i] = susceptible                   # S
        y0[i + n_cities] = exposed            # E
        y0[i + 2*n_cities] = infected         # I
        y0[i + 3*n_cities] = recovered        # R
    
    return y0

# 联立微分方程组
def seirs_model(t, y):
    dydt = np.zeros(4 * n_cities)
    
    # 提取各城市的SEIRS值
    S = y[0:n_cities]
    E = y[n_cities:2*n_cities]
    I = y[2*n_cities:3*n_cities]
    R = y[3*n_cities:4*n_cities]
    
    for i in range(n_cities):
        N = population[i]
        beta = get_beta(i)
        
        # 城市内部传播
        infection_within = beta * S[i] * I[i] / N
        
        # 城市间人口流动导致的传播
        infection_from_other_cities = 0
        for j in G.predecessors(i):
            if i != j:  # 排除自环
                flow_rate = G.edges[j, i]['weight']
                # 来自其他城市的感染者带来的新增感染
                infection_from_other_cities += flow_rate * beta * S[i] * I[j] / N
        
        # dS/dt: 易感者变化 = 康复者丧失免疫 - 新增感染
        dydt[i] = xi * R[i] - infection_within - infection_from_other_cities
        
        # dE/dt: 暴露者变化 = 新增感染 - 转为感染者
        dydt[i + n_cities] = infection_within + infection_from_other_cities - sigma * E[i]
        
        # dI/dt: 感染者变化 = 暴露者转为感染 - 康复
        dydt[i + 2*n_cities] = sigma * E[i] - gamma * I[i]
        
        # dR/dt: 康复者变化 = 感染者康复 - 丧失免疫
        dydt[i + 3*n_cities] = gamma * I[i] - xi * R[i]
    
    return dydt

# 运行模拟
days = 180  # 模拟6个月
t_span = (0, days)
t_eval = np.arange(0, days+1, 1)  # 每日输出结果

# 初始条件
y0 = get_initial_conditions()

# 求解微分方程
solution = solve_ivp(seirs_model, t_span, y0, t_eval=t_eval, method='RK45')

# 处理结果
t = solution.t
y = solution.y

# 数据可视化
plt.figure(figsize=(20, 15))

for i, city in enumerate(cities):
    plt.subplot(3, 3, i+1)
    
    S = y[i]
    E = y[i + n_cities]
    I = y[i + 2*n_cities]
    R = y[i + 3*n_cities]
    N = population[i]
    
    plt.plot(t, S/N, 'b-', label='易感者')
    plt.plot(t, E/N, 'y-', label='潜伏期')
    plt.plot(t, I/N, 'r-', label='感染者')
    plt.plot(t, R/N, 'g-', label='康复者')
    
    plt.title(f'{city} (人口: {population[i]/10000:.0f}万, 疫苗率: {vaccine_rate[i]:.0%}, 温度: {temperature[i]}°C)')
    plt.xlabel('天数')
    plt.ylabel('人口比例')
    plt.grid(True)
    plt.legend()
    plt.ylim(0, 1)

# 添加图例说明流行病学参数
plt.subplot(3, 3, n_cities+1)
plt.axis('off')
info_text = (
    f"模型参数:\n"
    f"潜伏期: {1/sigma:.1f}天\n"
    f"感染期: {1/gamma:.1f}天\n"
    f"免疫期: {1/xi:.1f}天\n"
    f"基本再生数R0: {base_R0}\n"
    f"模拟持续时间: {days}天\n"
    f"假设条件: 冬季, 开放政策"
)
plt.text(0.1, 0.5, info_text, fontsize=12)

# 添加感染高峰分析
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
    
    print(f"{city}: 感染高峰在第{peak_day}天, 感染率为{peak_infection:.2%}")

# 感染高峰日期与强度分析图表
df_peaks = pd.DataFrame({
    '城市': cities,
    '感染高峰日期': peak_days,
    '感染高峰比例': peak_infections,
    '人口(万)': population/10000,
    '温度(°C)': temperature,
    '疫苗接种率': vaccine_rate
})

# 绘制多维分析图
sns.scatterplot(data=df_peaks, x='温度(°C)', y='感染高峰比例', 
                size='人口(万)', hue='疫苗接种率', s=df_peaks['人口(万)']*2, alpha=0.7)
for i, row in df_peaks.iterrows():
    plt.annotate(row['城市'], (row['温度(°C)'], row['感染高峰比例']))
plt.title('城市感染率与温度、疫苗率、人口规模的关系')
plt.grid(True)

plt.tight_layout()
plt.savefig('covid_seirs_chinese_cities.png', dpi=300)
plt.show()
