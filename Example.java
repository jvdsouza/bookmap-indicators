public class Example {
    public static void main(String[] args) {
        System.out.println("Hello from Dockerized Java Build!");
        System.out.println("This JAR was compiled in a Docker container.");

        if (args.length > 0) {
            System.out.println("Arguments received:");
            for (int i = 0; i < args.length; i++) {
                System.out.println("  [" + i + "]: " + args[i]);
            }
        }
    }
}
