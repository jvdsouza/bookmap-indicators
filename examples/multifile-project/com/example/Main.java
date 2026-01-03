package com.example;

public class Main {
    public static void main(String[] args) {
        System.out.println("Multi-file Java Project Example");

        Calculator calc = new Calculator();
        int result = calc.add(5, 3);
        System.out.println("5 + 3 = " + result);

        Greeter greeter = new Greeter();
        greeter.greet("Docker User");
    }
}
