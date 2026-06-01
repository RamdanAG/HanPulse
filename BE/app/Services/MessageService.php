<?php
namespace App\Services;

use App\Events\ChatUpdate;
use App\Models\ChatRoom;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;

class MessageService
{
    public function index(Request $request){
        $user = $request->user();
        $data = User::where('id','!=',$user->id)->get();
        return [
            'message' => "Menampilkan daftar user",
            'success' => true,
            'status_code' => 200,
            'data' => $data
        ];
    }

    public function show(Request $request, int $receiverId){
        $user = $request->user();
        $chatRoom = ChatRoom::where(function($query) use ($user, $receiverId){
            $query->where('sender_id', $user->id)->where('receiver_id', $receiverId)->orWhere('sender_id', $receiverId)->where('receiver_id', $user->id);
        })->first();
        if(!$chatRoom){
            $chatRoom = ChatRoom::create([
                'sender_id' => $user->id,
                'receiver_id' => $receiverId
            ]);
        }

        $data = Message::with(['user'])->where('chat_room_id', $chatRoom->id)->get();
        return [
            'message' => "Menampilkan semua pesan",
            'success' => true,
            'status_code' => 200,
            'chat_room_id' => $chatRoom->id,
            'data' => $data,
        ];
    }

    public function store(Request $request){
        $user = $request->user();
        $chatRoom = ChatRoom::where(function($query) use ($user){
            $query->where('sender_id', $user->id)->orWhere('receiver_id', $user->id);
        })->where('id', $request->chat_room_id)->exists();

        if(!$chatRoom){
            return [
                'message' => "Anda tidak bisa akses room ini",
                'success' => false,
                'status_code' => 401
            ];
        }
        
        if($request->hasFile('image')){
            $image = $request->file('image');
            $nmimage = "image_" . time() . '.' . $image->getClientOriginalExtension();
            $imagePath = $image->storeAs('images/chat', $nmimage, 'public');
        }else{
            $imagePath = null;
        }

        $data = Message::create([
            'chat_room_id' => $request->chat_room_id,
            'user_id' => $user->id,
            'message' => $request->message,
            'image_path' => $imagePath
        ]);
        $data->load('user');
        broadcast(new ChatUpdate($data, $request->chat_room_id, 'create'));
        return [
            'message' => "Pesan berhasil dikirim",
            'success' => true,
            'status_code' => 201,
            'data' => $data
        ];
    }
}