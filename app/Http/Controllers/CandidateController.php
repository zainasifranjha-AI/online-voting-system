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
            // base64 already stored, return as is
            if ($c->symbol) {
                // agar purana path hai (storage wala) to null karo
                if (!str_starts_with($c->symbol, 'data:')) {
                    $c->symbol = null;
                }
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

        $imageBase64 = null;

        if ($request->hasFile('symbol')) {
            $file = $request->file('symbol');
            // 🔥 BASE64 ENCODE
            $imageData = file_get_contents($file->getRealPath());
            $base64 = base64_encode($imageData);
            $mime = $file->getMimeType();
            $imageBase64 = 'data:' . $mime . ';base64,' . $base64;
        }

        $candidate = Candidate::create([
            'name' => $request->name,
            'position' => $request->position,
            'symbol' => $imageBase64,
            'votes' => 0
        ]);

        return response()->json([
            'message' => 'Candidate added successfully',
            'data' => $candidate
        ]);
    }
}