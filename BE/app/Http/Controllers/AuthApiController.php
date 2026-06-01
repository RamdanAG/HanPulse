<?php

namespace App\Http\Controllers;

use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Services\AuthService;
use Illuminate\Http\Request;

class AuthApiController extends Controller
{
    protected $authService;
    public function __construct(AuthService $authService)
    {
        $this->authService = $authService;
    }

    public function login(LoginRequest $loginRequest){
        $data = $this->authService->login($loginRequest);
        return response()->json($data, $data['status_code']);
    }
    
    public function register(RegisterRequest $registerRequest){
        $data = $this->authService->register($registerRequest);
        return response()->json($data, $data['status_code']);
    }
}
