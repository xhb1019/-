import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import odeint

# 模型参数
N = 1e7          # 总人口
T_winter = 4      # 冬季平均温度（℃）
nu = 0.01         # 每日疫苗接种率（假设）
eta = 0.7         # 疫苗有效性
sigma = 1/5       # 潜伏期倒数（5天）
gamma = 1/10      # 恢复率（10天）
beta0 = 0.4       # 基础传播率

# 定义微分方程
def model(y, t, beta0, nu, eta, sigma, gamma):
    S, V, E, I, R = y
    beta = beta0 * beta_temp(T_winter) * mobility_factor(t)
    dSdt = -beta * S * I/N - nu * S
    dVdt = nu * S - eta * beta * V * I/N
    dEdt = beta * S * I/N + eta * beta * V * I/N - sigma * E
    dIdt = sigma * E - gamma * I
    dRdt = gamma * I
    return [dSdt, dVdt, dEdt, dIdt, dRdt]

# 初始条件（假设1%初始感染）
y0 = [N*0.99, 0, 0, N*0.01, 0]
t = np.linspace(0, 180, 180)  # 模拟180天

# 求解ODE
solution = odeint(model, y0, t, args=(beta0, nu, eta, sigma, gamma))
S, V, E, I, R = solution.T

# 可视化
plt.figure(figsize=(12,6))
plt.plot(t, I, label='Infected')
plt.xlabel('Days')
plt.ylabel('Population')
plt.title('Winter Policy Simulation: Infection Curve')
plt.legend()
plt.show()
