<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
{
    Schema::table('candidates', function (Blueprint $table) {
        $table->string('position')->nullable(); // ✅ ADD THIS
    });
}

    /**
     * Reverse the migrations.
     */
    public function down()
{
    Schema::table('candidates', function (Blueprint $table) {
        $table->dropColumn('position');
    });
}
};
