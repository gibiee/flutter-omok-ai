import logging
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

@app.errorhandler(500)
def server_error(e):
    logging.exception('An error occurred during a request.')
    return """
    An internal error occurred: <pre>{}</pre>
    See logs for full stacktrace.
    """.format(e), 500

@app.route('/ai_first_moved', methods=['POST'])
def receive_gameSet() :
    receive_data = request.get_json()
    print(receive_data)

    hard_idx = receive_data['hard_idx']

    board = Board(width=width, height=height, n_in_row=n)
    board.init_board(1)

    mcts_player = mcts_players[hard_idx]

    # AI가 先인 경우, 1번 먼저 돌을 둔다.
    ai_move = mcts_player.get_action(board)
    ai_loc = board.move_to_location(ai_move)
    
    states_loc = [[0] * 9 for _ in range(9)]
    states_loc[ai_loc[0]][ai_loc[1]] = 2

    data = {'ai_moved' : list(map(int, ai_loc)), 'states_loc' : states_loc, 'message' : None}
    return jsonify(data)

@app.route('/player_moved', methods=['POST'])
def player_moved():
    receive_data = request.get_json()
    print(receive_data)
    
    # 난이도에 해당하는 player 불러옴.
    hard_idx = receive_data['hard_idx']

    board = Board(width=width, height=height, n_in_row=n)
    board.init_board(0)
    
    states_loc = receive_data['states_loc']
    if states_loc != None :
        board.states_loc = states_loc
        board.states_loc_to_states()
    
    # 플레이어가 둔 돌의 위치를 받고
    player_loc = receive_data['player_moved']
    player_move = board.location_to_move(player_loc)
    board.do_move(player_move)
    board.set_forbidden() # 금수 자리 업데이트

    print(np.array(board.states_loc))
    print(board.states)

    # 승리 판정 (플레이어가 이겼는지)
    end, winner = board.game_end()
    if end :
        if winner == -1 : message = "tie"
        else : message = winner

        data = {'ai_moved': None, 'forbidden': board.forbidden_locations, 'message' : message}
        return jsonify(data)

    # AI가 둘 위치를 보낸다.
    mcts_player = mcts_players[hard_idx]

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
    
    data = {'ai_moved' : list(map(int, ai_loc)), 'states_loc' : board.states_loc, 'forbidden' : board.forbidden_locations, 'message' : message}
    return jsonify(data)

if __name__ == '__main__':
    n = 5
    width, height = 9, 9
    hards = [2500, 5000, 7500, 10000, 12500, 15000, 17500, 20000]
    mcts_players = []
    for hard in hards :
        model_file = f'./model/policy_9_{hard}.model'
        policy_param = pickle.load(open(model_file, 'rb'), encoding='bytes')
        best_policy = PolicyValueNetNumpy(width, height, policy_param)
    
        mcts_player = MCTSPlayer(best_policy.policy_value_fn, c_puct=5, n_playout=400)
        mcts_players.append(mcts_player)

    app.run(host='0.0.0.0', port=8080, debug=True)
    # app.run() # run_with_ngrok