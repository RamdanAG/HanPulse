<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('chat_room', function (Blueprint $table) {
            $table->integer('id')->primary()->autoIncrement();
            $table->integer('sender_id');
            $table->integer('receiver_id');
            $table->timestamps();

            $table->foreign('sender_id')->on('users')->references('id')->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('receiver_id')->on('users')->references('id')->onDelete('cascade')->onUpdate('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('chat_room');
    }
};
