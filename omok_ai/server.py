from flask import Flask, jsonify, request
# from flask_ngrok import run_with_ngrok

import pickle
from human_play import Human
from game import Board, Game
from mcts_alphaZero import MCTSPlayer
from policy_value_net_numpy import PolicyValueNetNumpy

import numpy as np

app = Flask(__name__)
# run_with_ngrok(app)

@app.route('/gameSet', methods=['POST'])
def receive_gameSet() :
    global n, width, height, hard, order, board, game, mcts_player, human

    n = 5
    width, height = 9, 9
    # 5000
    hards = [2500, 7500, 10000, 12500, 15000, 20000]
    hard = hards[request.get_json()['hard']]
    order = request.get_json()['player_is_black']
    if order == True : order = 0
    else : order = 1

    model_file = f'./model/policy_9_{hard}.model'
    board = Board(width=width, height=height, n_in_row=n)
    game = Game(board)

    policy_param = pickle.load(open(model_file, 'rb'), encoding='bytes')
    best_policy = PolicyValueNetNumpy(width, height, policy_param)
    
    mcts_player = MCTSPlayer(best_policy.policy_value_fn, c_puct=5, n_playout=400)
    human = Human()

    board.init_board(order)

    print(hard, order)

    # 플레이어가 先인 경우
    if order == 0 : return 'OK'
    # AI가 先인 경우, 1번 먼저 돌을 둔다.
    else :
        ai_move = mcts_player.get_action(board)
        ai_loc = board.move_to_location(ai_move)
        board.do_move(ai_move)
        board.set_forbidden() # 금수 자리 업데이트

        data = {'ai_moved' : list(map(int, ai_loc)), 'forbidden' : board.forbidden_locations, 'message' : None}
        return jsonify(data)

@app.route('/player_moved', methods=['POST'])
def player_moved():

    # 플레이어가 둔 돌의 위치를 받고
    player_loc = request.get_json()['player_moved']
    player_move = board.location_to_move(player_loc)
    board.do_move(player_move)
    board.set_forbidden() # 금수 자리 업데이트

    print(np.array(board.states_loc))

    # 승리 판정 (플레이어가 이겼는지)
    end, winner = board.game_end()
    if end :
        if winner == -1 : message = "tie"
        else : message = winner

        data = {'ai_moved': None, 'forbidden': board.forbidden_locations, 'message' : message}
        return jsonify(data)

    # AI가 둘 위치를 보낸다.
    ai_move = mcts_player.get_action(board)
    ai_loc = board.move_to_location(ai_move)
    board.do_move(ai_move)
    board.set_forbidden() # 금수 자리 업데이트

    print(np.array(board.states_loc))
    
    # 승리 판정 (AI가 이겼는지)
    message = None
    end, winner = board.game_end()
    if end :
        if winner == -1 : message = "tie"
        else : message = winner
    
    data = {'ai_moved' : list(map(int, ai_loc)), 'forbidden' : board.forbidden_locations, 'message' : message}
    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True)
    # app.run() # run_with_ngrok