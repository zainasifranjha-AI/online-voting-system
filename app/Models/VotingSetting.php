<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VotingSetting extends Model
{
    protected $fillable = [
        'start_time',
        'end_time'
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime',
    ];
}