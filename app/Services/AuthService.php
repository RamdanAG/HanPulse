<?php
namespace App\Services;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    public function login(Request $request){
        $user = User::where('email', $request->email)->first();
        if(!$user){
            return [
                'success' => false,
                'message' => "Email anda tidak terdaftar di sistem",
                'status_code' => 401
            ];
        }

        if(Hash::check($request->password, $user->password)){
            $data = [
                'name' => $user->name,
                'token' => $user->createToken('auth-token')->plainTextToken
            ];
            return [
                'message' => "Login berhasil",
                'success' => true,
                'status_code' => 200,
                'data' => $data
            ];
        }else{
            return [
                'message' => "Password anda salah",
                'success' => false,
                'status_code' => 401
            ];
        }
    }

    public function register(Request $request){
        if($request->hasFile('profile')){
            $profile = $request->file('profile');
            $nmprofile = "profile_" . time() . '.' . $profile->getClientOriginalExtension();
            $profilePath = $profile->storeAs('images/profile', $nmprofile, 'public');
        }else{
            $profilePath = null;
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => $request->password,
            'profile' => $profilePath
        ]);

        $data = [
            'name' => $user->name,
            'token' => $user->createToken('auth-token')->plainTextToken
        ];
        return [
            'message' => "Register berhasil",
            'success' => true,
            'status_code' => 201,
            'data' => $data
        ];
    }
}