<?php

namespace App\Http\Controllers;

use App\Models\Vote;
use App\Models\Candidate;
use App\Models\User;
use App\Models\VotingSetting;
use Illuminate\Http\Request;
use Carbon\Carbon;

class VoteController extends Controller
{
    // 🗳️ CAST VOTE
    public function vote(Request $request)
    {
        // ✅ VALIDATION
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'candidate_id' => 'required|exists:candidates,id',
        ]);

        // 🔥 CHECK USER
        $user = User::find($request->user_id);
        if (!$user) {
            return response()->json([
                'message' => 'User not found'
            ], 404);
        }

        // 🔥 CHECK CANDIDATE
        $candidate = Candidate::find($request->candidate_id);
        if (!$candidate) {
            return response()->json([
                'message' => 'Candidate not found'
            ], 404);
        }

        // 🔥 VOTING TIME CHECK (FIXED)
        $setting = VotingSetting::first();

        if ($setting) {
            // Compare in Asia/Karachi (business timezone) to match DB storage.
            $now = Carbon::now('Asia/Karachi');
            $start = $setting->start_time ? $setting->start_time->clone()->timezone('Asia/Karachi') : null;
            $end = $setting->end_time ? $setting->end_time->clone()->timezone('Asia/Karachi') : null;

            if ($start && $now->lt($start)) {
                return response()->json([
                    'message' => 'Voting has not started yet'
                ], 400);
            }

            if ($end && $now->gt($end)) {
                return response()->json([
                    'message' => 'Voting has ended'
                ], 400);
            }
        }

        // 🔥 ONE USER = ONE VOTE
        $alreadyVoted = Vote::where('user_id', $user->id)->exists();

        if ($alreadyVoted) {
            return response()->json([
                'message' => 'You have already voted'
            ], 400);
        }

        // 🗳️ CREATE VOTE
        $vote = Vote::create([
            'user_id' => $user->id,
            'candidate_id' => $candidate->id
        ]);

        // 📊 INCREMENT VOTES
        $candidate->increment('votes');

        return response()->json([
            'message' => 'Vote cast successfully',
            'vote' => $vote
        ]);
    }

    // 📋 ALL VOTES
    public function voteList()
    {
        $votes = Vote::with(['user', 'candidate'])->latest()->get();
        return response()->json($votes);
    }

    // 📊 RESULTS
    public function results()
    {
        $candidates = Candidate::orderBy('votes', 'desc')->get();
        return response()->json($candidates);
    }
}