<?php

namespace App\Http\Controllers;

use App\Models\Candidate;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CandidateController extends Controller
{
    // 📋 GET ALL CANDIDATES
    public function index()
    {
        $candidates = Candidate::all()->map(function ($c) {
            if ($c->symbol) {
                $c->symbol = asset(Storage::url($c->symbol));
            } else {
                $c->symbol = null;
            }

            return $c;
        });

        return response()->json($candidates);
    }

    // ➕ ADD CANDIDATE
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'position' => 'required|string|max:255',
            'symbol' => 'nullable|image|mimes:jpg,jpeg,png|max:2048'
        ]);

        $imagePath = null;

        if ($request->hasFile('symbol')) {

            $file = $request->file('symbol');

            // 🔥 UNIQUE NAME
            $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();

            // 🔥 STORE
            $imagePath = $file->storeAs('symbols', $filename, 'public');
        }

        $candidate = Candidate::create([
            'name' => $request->name,
            'position' => $request->position,
            'symbol' => $imagePath,
            'votes' => 0
        ]);

        return response()->json([
            'message' => 'Candidate added successfully',
            'data' => $candidate
        ]);
    }
}