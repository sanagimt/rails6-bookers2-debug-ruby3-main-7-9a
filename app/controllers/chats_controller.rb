class ChatsController < ApplicationController
    #showアクションで関係のないユーザーをブロック
    before_action :block_non_related_users, only: [:show]

    #チャットルームの表示
    def show
        #チャット相手のユーザー取得
        @user = User.find(params[:id])
        #現在のユーザーが参加しているチャットルームの一覧取得
        rooms = current_user.user_rooms.pluck(:room_id)
        #相手ユーザーとの共有チャットルームが存在するか確認
        user_rooms = UserRoom.find_by(user_id: @user.id, room_id: rooms)
        
        #共有チャットルームが存在するか（nilでないか）
        unless user_rooms.nil?
            #存在する場合、チャットルームを表示
            @room = user_rooms.room
        else
            #存在しない場合、新しいチャットルームを作成
            @room = Room.new
            @room.save
            #チャットルームに現在のユーザーと相手ユーザーを追加
            UserRoom.create(user_id: current_user.id, room_id: @room.id)
            UserRoom.create(user_id: @user.id, room_id: @room.id)
        end
    
        #チャットルームに関連付けられたメッセージを取得
        @chats = @room.chats
        #新しいメッセージを作成するための空のchatオブジェクトを生成
        @chat = Chat.new(room_id: @room.id)
    
    end

    #チャットメッセージの作成
    def create
        #フォームから送信されたメッセージを取得し、現在のユーザーに関連づけて保存
        @chat = current_user.chats.new(chat_params)
    end

    private

    #フォームから送信されたパラメータを安全に取得
    def chat_params
        params.require(:chat).permit(:message, :room_id)
    end
    
    #FF外のユーザーをブロックする
    def block_non_related_users
        #チャット相手のユーザーを取得
        user = User.find(params[:id])
        #ユーザーがFFであるか確認、FF外の場合はリダイレクト
        unless current_user.following?(user) && user.following?(current_user)
            redirect_back(fallback_location: root_path)
        end
    end
end
