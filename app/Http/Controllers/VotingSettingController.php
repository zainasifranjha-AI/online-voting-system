<?php

namespace App\Http\Controllers;

use App\Models\VotingSetting;
use Illuminate\Http\Request;
use Carbon\Carbon;

class VotingSettingController extends Controller
{
    /**
     * Always return timestamps with an explicit timezone offset.
     *
     * This project uses Asia/Karachi as the business timezone (config/app.php),
     * and DB values are stored as local datetimes (no timezone column).
     * Returning ISO8601 with +05:00 removes ambiguity on the client.
     */
    public function getTime()
    {
        $setting = VotingSetting::first();

        if (!$setting) {
            return response()->json([
                'start_time' => null,
                'end_time' => null
            ]);
        }

        return response()->json([
            'start_time' => $setting->start_time
                ? $setting->start_time->clone()->timezone('Asia/Karachi')->toIso8601String()
                : null,
            'end_time' => $setting->end_time
                ? $setting->end_time->clone()->timezone('Asia/Karachi')->toIso8601String()
                : null,
        ]);
    }

    /**
     * Accepts admin-selected local time (Asia/Karachi) and stores it as local
     * datetime (matching app timezone + DB storage).
     */
    public function setVotingTime(Request $request)
    {
        $request->validate([
            'start_time' => 'required',
            'end_time' => 'required',
        ]);

        $start = Carbon::parse($request->start_time, 'Asia/Karachi')->timezone('Asia/Karachi');
        $end = Carbon::parse($request->end_time, 'Asia/Karachi')->timezone('Asia/Karachi');

        VotingSetting::updateOrCreate(
            ['id' => 1],
            [
                'start_time' => $start,
                'end_time' => $end,
            ]
        );

        return response()->json([
            'message' => 'Voting time saved successfully',
            'start_time' => $start->toIso8601String(),
            'end_time' => $end->toIso8601String(),
        ]);
    }
}