<?php

namespace App\Tests;

use App\Calculator;
use PHPUnit\Framework\TestCase;

class CalculatorTest extends TestCase
{
    private Calculator $calc;

    protected function setUp(): void
    {
        $this->calc = new Calculator();
    }

    public function testAdd(): void
    {
        $this->assertSame(5.0, $this->calc->add(2, 3));
    }

    public function testSub(): void
    {
        $this->assertSame(-1.0, $this->calc->sub(2, 3));
    }

    public function testMul(): void
    {
        $this->assertSame(6.0, $this->calc->mul(2, 3));
    }

    public function testDiv(): void
    {
        $this->assertSame(2.0, $this->calc->div(6, 3));
    }

    public function testDivByZero(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->calc->div(1, 0);
    }
}