<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $table = "message";
    protected $fillable = ['chat_room_id','user_id','message','image_path'];
    function user(){
        return $this->belongsTo(User::class,'user_id');
    }
}
