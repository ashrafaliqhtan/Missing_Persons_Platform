""" jazan u """
import numpy as np
import itertools
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from tqdm import tqdm
from enum import Enum
import warnings
warnings.filterwarnings('ignore')
class LearningAlgorithm(Enum):
    Q_LEARNING = "Q-Learning"
    SARSA = "SARSA"

class TowerOfHanoiQLearning:
    
    def __init__(self, n_discs: int = 3):
        self.n_discs = n_discs
        self.optimal_moves = 2**n_discs - 1
        self.valid_states = self._generate_valid_states()
        self.state_to_idx = {state: idx for idx, state in enumerate(self.valid_states)}
        self.idx_to_state = {idx: state for state, idx in self.state_to_idx.items()}
        self.R = self._generate_reward_matrix()
        
        print(f"🏛️ Tower of Hanoi Project - {n_discs} Discs")
        print(f"📊 Valid States: {len(self.valid_states)} | Optimal Solution: {self.optimal_moves} moves")
    
    def _is_valid_state(self, state: tuple) -> bool:
        for peg in range(3):
            discs_on_peg = [disc for disc in range(self.n_discs) if state[disc] == peg]
            if discs_on_peg != sorted(discs_on_peg):
                return False
        return True
    
    def _generate_valid_states(self) -> list:
        all_states = list(itertools.product(range(3), repeat=self.n_discs))
        return [state for state in all_states if self._is_valid_state(state)]
    
    def _get_valid_moves(self, state: tuple) -> list:
        moves = []
        for from_peg in range(3):
            discs_from = [disc for disc in range(self.n_discs) if state[disc] == from_peg]
            if not discs_from:
                continue
                
            disc_to_move = min(discs_from)  # Smallest disc (top disc)
            
            for to_peg in range(3):
                if from_peg == to_peg:
                    continue
                    
                discs_to = [disc for disc in range(self.n_discs) if state[disc] == to_peg]
                
                if not discs_to or min(discs_to) > disc_to_move:
                    new_state = list(state)
                    new_state[disc_to_move] = to_peg
                    new_state_tuple = tuple(new_state)
                    
                    if self._is_valid_state(new_state_tuple):
                        moves.append(new_state_tuple)
        
        return moves
    
    def _generate_reward_matrix(self) -> np.ndarray:
        n_states = len(self.valid_states)
        R = np.full((n_states, n_states), -np.inf)
        
        print("🔄 Generating reward matrix...")
        
        for i, state in enumerate(tqdm(self.valid_states, desc="States")):
            for next_state in self._get_valid_moves(state):
                j = self.state_to_idx[next_state]
                R[i, j] = -0.1  # Small penalty for each move
        
        # Large reward for final state
        final_state = tuple([2] * self.n_discs)
        if final_state in self.state_to_idx:
            final_idx = self.state_to_idx[final_state]
            R[:, final_idx] = 100  # Achievement reward
            
        return R
    
    def train(self, algorithm: LearningAlgorithm = LearningAlgorithm.Q_LEARNING, 
              n_episodes: int = 1000, gamma: float = 0.95, alpha: float = 0.1, 
              epsilon: float = 0.1, epsilon_decay: float = 0.995) -> np.ndarray:
        n_states = len(self.valid_states)
        Q = np.zeros((n_states, n_states))
        current_epsilon = epsilon
        
        print(f"🧠 Training {algorithm.value} for {n_episodes} episodes...")
        
        for episode in tqdm(range(n_episodes), desc="Training"):
            state = 0  # Initial state (all discs on peg 0)
            
            for step in range(100):  # Maximum steps
                valid_actions = np.where(self.R[state, :] > -np.inf)[0]
                if len(valid_actions) == 0:
                    break
                
                # Choose action (exploration vs exploitation)
                if np.random.random() < current_epsilon:
                    action = np.random.choice(valid_actions)
                else:
                    q_values = Q[state, valid_actions]
                    action = valid_actions[np.argmax(q_values)]
                
                # Update Q-value based on algorithm
                reward = self.R[state, action]
                next_state = action
                
                if algorithm == LearningAlgorithm.Q_LEARNING:
                    # Q-learning update
                    next_valid = np.where(self.R[next_state, :] > -np.inf)[0]
                    next_max_q = np.max(Q[next_state, next_valid]) if len(next_valid) > 0 else 0
                    Q[state, action] = (1 - alpha) * Q[state, action] + alpha * (reward + gamma * next_max_q)
                
                elif algorithm == LearningAlgorithm.SARSA:
                    # SARSA update
                    next_valid = np.where(self.R[next_state, :] > -np.inf)[0]
                    if len(next_valid) > 0:
                        if np.random.random() < current_epsilon:
                            next_action = np.random.choice(next_valid)
                        else:
                            next_q_values = Q[next_state, next_valid]
                            next_action = next_valid[np.argmax(next_q_values)]
                        next_q = Q[next_state, next_action]
                        Q[state, action] = (1 - alpha) * Q[state, action] + alpha * (reward + gamma * next_q)
                
                # Move to next state
                state = next_state
                
                # Stop if reached final state
                if reward > 50:
                    break
            
            # Decrease exploration rate
            current_epsilon = max(0.01, current_epsilon * epsilon_decay)
        
        return Q
    
    def get_policy(self, Q: np.ndarray) -> list:
        policy = []
        for i in range(Q.shape[0]):
            valid_actions = np.where(self.R[i, :] > -np.inf)[0]
            if len(valid_actions) == 0:
                policy.append([])
                continue
            
            q_values = Q[i, valid_actions]
            max_q = np.max(q_values)
            best_actions = valid_actions[np.where(q_values == max_q)[0]]
            policy.append(best_actions.tolist())
        
        return policy
    
    def evaluate_policy(self, policy: list, n_games: int = 100) -> dict:
        moves = []
        successes = 0
        final_idx = self.state_to_idx.get(tuple([2] * self.n_discs), -1)
        
        for _ in range(n_games):
            state = 0
            move_count = 0
            
            while state != final_idx and move_count < 100:
                if not policy[state]:
                    break
                
                next_state = np.random.choice(policy[state])
                state = next_state
                move_count += 1
            
            if state == final_idx:
                successes += 1
                moves.append(move_count)
            else:
                moves.append(100)  # Penalty for failure
        
        return {
            'mean_moves': np.mean(moves),
            'std_moves': np.std(moves),
            'success_rate': successes / n_games,
            'efficiency': self.optimal_moves / np.mean(moves) if np.mean(moves) > 0 else 0,
            'optimality_ratio': np.mean(moves) / self.optimal_moves
        }

    # ORIGINAL VERSION PLOTTING FUNCTIONS
    def original_learn_Q(self, R, gamma=0.8, alpha=1.0, N_episodes=1000):
        Q = np.zeros(R.shape)
        states = list(range(R.shape[0]))
        
        for n in range(N_episodes):
            state = np.random.choice(states)
            next_states = np.where(R[state, :] >= 0)[0]
            
            if len(next_states) == 0:
                continue
                
            next_state = np.random.choice(next_states)
            next_next_states = np.where(R[next_state, :] >= 0)[0]
            
            V = np.max(Q[next_state, next_next_states]) if len(next_next_states) > 0 else 0
            
            Q[state, next_state] = (1 - alpha) * Q[state, next_state] + alpha * (R[state, next_state] + gamma * V)
        
        if np.max(Q) > 0:
            Q /= np.max(Q)
        
        return Q

    def original_get_policy(self, Q, R):
        policy = []
        for i in range(Q.shape[0]):
            valid_actions = np.where(R[i, :] >= 0)[0]
            if len(valid_actions) == 0:
                policy.append([])
                continue
                
            q_values = Q[i, valid_actions]
            max_q = np.max(q_values)
            best_actions = valid_actions[np.where(q_values == max_q)[0]]
            policy.append(best_actions.tolist())
        
        return policy

    def original_play(self, policy, max_moves=1000):

        start_state = 0
        end_state = len(policy) - 1
        state = start_state
        moves = 0
        
        while state != end_state and moves < max_moves:
            if not policy[state]:
                break
            state = np.random.choice(policy[state])
            moves += 1
        
        return moves if state == end_state else max_moves

    def original_play_average(self, policy, play_times=100):


        moves = np.zeros(play_times)
        for n in range(play_times):
            moves[n] = self.original_play(policy)
        return np.mean(moves), np.std(moves)

    def original_Q_performance(self, R, episodes, play_times=100):
        means = np.zeros(len(episodes))
        stds = np.zeros(len(episodes))
        
        for n, N_episodes in enumerate(episodes):
            Q = self.original_learn_Q(R, N_episodes=N_episodes)
            policy = self.original_get_policy(Q, R)
            means[n], stds[n] = self.original_play_average(policy, play_times)
        
        return means, stds

    def original_Q_performance_average(self, R, episodes, learn_times=10, play_times=100):
        means_times = np.zeros((learn_times, len(episodes)))
        stds_times = np.zeros((learn_times, len(episodes)))
        
        for n in range(learn_times):
            means_times[n, :], stds_times[n, :] = self.original_Q_performance(R, episodes, play_times=play_times)
        
        means_averaged = np.mean(means_times, axis=0)
        stds_averaged = np.mean(stds_times, axis=0)
        
        return means_averaged, stds_averaged

    def plot_original_results(self, episodes, means_averaged, stds_averaged, N, block=False):
        """Original version plotting function"""
        fig = plt.figure(figsize=(10, 6))
        plt.loglog(episodes, means_averaged, 'b.-', label='Average performance', linewidth=2)
        plt.loglog(episodes, means_averaged + stds_averaged, 'b', alpha=0.5)
        plt.loglog(episodes, means_averaged - stds_averaged, 'b', alpha=0.5)
        plt.fill_between(episodes, means_averaged - stds_averaged, means_averaged + stds_averaged, 
                        facecolor='blue', alpha=0.5)
        optimum_moves = 2**N - 1
        plt.axhline(y=optimum_moves, color='g', label=f'Optimum ({optimum_moves} moves)')
        plt.xlabel('Number of training episodes')
        plt.ylabel('Number of moves')
        plt.grid(True, which='both', alpha=0.3)
        plt.title(f'Q-learning the Towers of Hanoi game with {N} discs (Original)')
        plt.legend()
        plt.show(block=block)

class HanoiAnalyzer:

    def __init__(self):
        self.results = {}
    
    def compare_algorithms(self, n_discs: int = 3, n_runs: int = 5):
        """Compare performance of different algorithms"""
        game = TowerOfHanoiQLearning(n_discs)
        algorithms = [LearningAlgorithm.Q_LEARNING, LearningAlgorithm.SARSA]
        episodes_list = [100, 500, 1000, 2000]
        
        results = []
        
        print(f"🔍 Comparing algorithms for {n_discs} discs...")
        
        for algo in algorithms:
            print(f"📊 Testing {algo.value}...")
            
            for episodes in episodes_list:
                algo_results = []
                
                for run in range(n_runs):
                    Q = game.train(algo, n_episodes=episodes)
                    policy = game.get_policy(Q)
                    performance = game.evaluate_policy(policy, 50)
                    algo_results.append(performance)
                
                # Average results
                avg_performance = {
                    'algorithm': algo.value,
                    'episodes': episodes,
                    'mean_moves': np.mean([r['mean_moves'] for r in algo_results]),
                    'std_moves': np.std([r['mean_moves'] for r in algo_results]),
                    'success_rate': np.mean([r['success_rate'] for r in algo_results]),
                    'efficiency': np.mean([r['efficiency'] for r in algo_results]),
                    'optimality': np.mean([r['optimality_ratio'] for r in algo_results])
                }
                results.append(avg_performance)
                
                print(f"   {episodes:4d} episodes: {avg_performance['mean_moves']:5.1f} moves "
                      f"({avg_performance['success_rate']:.1%} success)")
        
        self.results[n_discs] = results
        return pd.DataFrame(results)
    
    def plot_comprehensive_analysis(self, results_df: pd.DataFrame, n_discs: int):
        """Plot comprehensive analysis results"""
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        fig.suptitle(f'Comprehensive Tower of Hanoi Analysis - {n_discs} Discs\n'
                    f'Optimal Solution: {2**n_discs - 1} moves', fontsize=16, fontweight='bold')
        
        # Plot 1: Average Moves
        for algo in results_df['algorithm'].unique():
            algo_data = results_df[results_df['algorithm'] == algo]
            axes[0,0].plot(algo_data['episodes'], algo_data['mean_moves'], 'o-', 
                          label=algo, linewidth=3, markersize=8)
        
        axes[0,0].axhline(y=2**n_discs-1, color='red', linestyle='--', 
                         linewidth=2, label='Optimal Solution')
        axes[0,0].set_xlabel('Training Episodes')
        axes[0,0].set_ylabel('Average Moves')
        axes[0,0].set_title('Learning Performance: Moves')
        axes[0,0].legend()
        axes[0,0].grid(True, alpha=0.3)
        
        # Plot 2: Success Rate
        for algo in results_df['algorithm'].unique():
            algo_data = results_df[results_df['algorithm'] == algo]
            axes[0,1].plot(algo_data['episodes'], algo_data['success_rate']*100, 'o-',
                          label=algo, linewidth=3, markersize=8)
        
        axes[0,1].set_xlabel('Training Episodes')
        axes[0,1].set_ylabel('Success Rate (%)')
        axes[0,1].set_title('Learning Performance: Success Rate')
        axes[0,1].legend()
        axes[0,1].grid(True, alpha=0.3)
        
        # Plot 3: Efficiency
        for algo in results_df['algorithm'].unique():
            algo_data = results_df[results_df['algorithm'] == algo]
            axes[0,2].plot(algo_data['episodes'], algo_data['efficiency']*100, 'o-',
                          label=algo, linewidth=3, markersize=8)
        
        axes[0,2].set_xlabel('Training Episodes')
        axes[0,2].set_ylabel('Efficiency (%)')
        axes[0,2].set_title('Learning Performance: Efficiency')
        axes[0,2].legend()
        axes[0,2].grid(True, alpha=0.3)
        
        # Plot 4: Optimality Ratio
        for algo in results_df['algorithm'].unique():
            algo_data = results_df[results_df['algorithm'] == algo]
            axes[1,0].plot(algo_data['episodes'], algo_data['optimality'], 'o-',
                          label=algo, linewidth=3, markersize=8)
        
        axes[1,0].axhline(y=1.0, color='red', linestyle='--', linewidth=2, label='Perfect Optimality')
        axes[1,0].set_xlabel('Training Episodes')
        axes[1,0].set_ylabel('Optimality Ratio')
        axes[1,0].set_title('Solution Optimality')
        axes[1,0].legend()
        axes[1,0].grid(True, alpha=0.3)
        
        # Plot 5: Performance Heatmap
        pivot_data = results_df.pivot(index='episodes', columns='algorithm', values='efficiency')
        sns.heatmap(pivot_data, annot=True, fmt='.1%', cmap='YlOrRd', ax=axes[1,1])
        axes[1,1].set_title('Efficiency Heatmap')
        
        # Plot 6: Standard Deviation
        for algo in results_df['algorithm'].unique():
            algo_data = results_df[results_df['algorithm'] == algo]
            axes[1,2].plot(algo_data['episodes'], algo_data['std_moves'], 'o-',
                          label=algo, linewidth=3, markersize=8)
        
        axes[1,2].set_xlabel('Training Episodes')
        axes[1,2].set_ylabel('Standard Deviation')
        axes[1,2].set_title('Performance Consistency')
        axes[1,2].legend()
        axes[1,2].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.show()
    
    def run_original_analysis(self):

        print("\n" + "="*60)
        print("ORIGINAL VERSION ANALYSIS")
        print("="*60)
        
        configurations = [
            (2, [1, 10, 30, 60, 100, 300, 600, 1000], 5, 50),
            (3, [1, 10, 30, 100, 300, 600, 1000, 3000], 3, 20),
            (4, [10, 100, 200, 300, 1000, 2000, 3000, 6000], 2, 10)
        ]
        
        for N, episodes, learn_times, play_times in configurations:
            print(f"\nAnalyzing {N} discs with original version...")
            
            game = TowerOfHanoiQLearning(N)
            means_averaged, stds_averaged = game.original_Q_performance_average(
                game.R, episodes, learn_times=learn_times, play_times=play_times
            )
            
            game.plot_original_results(episodes, means_averaged, stds_averaged, N)
            
            # Print results
            optimum = 2**N - 1
            print(f"Results for {N} discs (Optimal: {optimum} moves):")
            for i, ep in enumerate(episodes):
                ratio = means_averaged[i] / optimum
                print(f"  {ep:6d} episodes: {means_averaged[i]:6.1f} moves (ratio: {ratio:.2f})")

def main():

    print("=" * 70)
    print("🏛️ TOWER OF HANOI Q-LEARNING COMPREHENSIVE PROJECT")
    print("=" * 70)
    
    # Apply styling
    plt.style.use('default')
    sns.set_palette("husl")
    
    analyzer = HanoiAnalyzer()
    
    # 1. Run original version analysis
    print("\n1. 📊 ORIGINAL VERSION ANALYSIS")
    print("-" * 50)
    analyzer.run_original_analysis()
    
    # 2. Advanced algorithm comparison
    print("\n2. 🧪 ADVANCED ALGORITHM COMPARISON")
    print("-" * 50)
    
    for n_discs in [2, 3]:
        print(f"\n>>> Analyzing {n_discs} discs:")
        results_df = analyzer.compare_algorithms(n_discs, n_runs=3)
        analyzer.plot_comprehensive_analysis(results_df, n_discs)
        
        # Display best results
        best_result = results_df.loc[results_df['efficiency'].idxmax()]
        print(f"\n🏆 BEST PERFORMANCE for {n_discs} discs:")
        print(f"   Algorithm: {best_result['algorithm']}")
        print(f"   Episodes: {best_result['episodes']}")
        print(f"   Moves: {best_result['mean_moves']:.1f} (Optimal: {2**n_discs-1})")
        print(f"   Success Rate: {best_result['success_rate']:.1%}")
        print(f"   Efficiency: {best_result['efficiency']:.1%}")
    
    # 3. Demonstration
    print("\n3. 🎯 DEMONSTRATION")
    print("-" * 50)
    
    # Create game with 3 discs
    game = TowerOfHanoiQLearning(3)
    
    # Quick training and results
    print("Quick training demonstration...")
    Q = game.train(LearningAlgorithm.Q_LEARNING, n_episodes=500)
    policy = game.get_policy(Q)
    performance = game.evaluate_policy(policy)
    
    print(f"\n📊 DEMONSTRATION RESULTS:")
    print(f"   Average Moves: {performance['mean_moves']:.1f}")
    print(f"   Success Rate: {performance['success_rate']:.1%}")
    print(f"   Efficiency: {performance['efficiency']:.1%}")
    print(f"   Optimality Ratio: {performance['optimality_ratio']:.2f}")
    
    print("\n" + "=" * 70)
    print("🎉 PROJECT COMPLETED SUCCESSFULLY!")
    print("=" * 70)

if __name__ == "__main__":
    main()