<?php

use App\Models\ChatRoom;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('chat-room-{id}', function ($user, $id) {
    return ChatRoom::where(function ($query) use ($user){
        $query->where('sender_id', $user->id)->orWhere('receiver_id', $user->id);
    })->where('id', $id)->exists()
    ? [
        'id' => $user->id,
        'name' => $user->name,
        'email' => $user->email
    ]
    : false;
});
