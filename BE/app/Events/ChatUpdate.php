<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatUpdate implements ShouldBroadcast, ShouldQueue
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    public $message;
    public int $chatRoomId;
    public string $action;

    /**
     * Create a new event instance.
     */
    public function __construct($message, $chatRoomId, $action)
    {
        $this->message = $message;
        $this->chatRoomId = $chatRoomId;
        $this->action = $action;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PresenceChannel('chat-room-' . $this->chatRoomId),
        ];
    }

    public function broadcastAs(){
        return "chatUpdate";
    }

    public function broadcastWith(){
        return [
            'message' => $this->message,
            'action' => $this->action
        ];
    }
}
