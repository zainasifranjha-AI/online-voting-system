<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        if (!User::where('email', 'CallmeEthi.com')->exists()) {
            User::create([
                'name' => 'Admin',
                'email' => 'CallmeEthi.com',
                'password' => Hash::make('123456'),
                'role' => 'admin',
            ]);
        }
    }
}