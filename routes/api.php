<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CandidateController;
use App\Http\Controllers\VoteController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminController;

Route::get('/candidates', [CandidateController::class, 'index']);
Route::post('/candidates', [CandidateController::class, 'store']);

Route::post('/vote', [VoteController::class, 'vote']);
Route::get('/results', [VoteController::class, 'results']);
Route::get('/votes', [VoteController::class, 'voteList']);

Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

Route::post('/set-voting-time', [AdminController::class, 'setVotingTime']);
Route::post('/clear-election', [AdminController::class, 'clearElection']);
Route::get('/get-voting-time', [App\Http\Controllers\VotingSettingController::class, 'getTime']);