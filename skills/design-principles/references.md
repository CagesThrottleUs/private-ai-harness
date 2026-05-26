 Applicability
 Use the Factory Method when you don’t know beforehand the exact types and dependencies of the objects your code should work with.

 The Factory Method separates product construction code from the code that actually uses the product. Therefore it’s easier to extend the product construction code independently from the rest of the code.

For example, to add a new product type to the app, you’ll only need to create a new creator subclass and override the factory method in it.

 Use the Factory Method when you want to provide users of your library or framework with a way to extend its internal components.

 Inheritance is probably the easiest way to extend the default behavior of a library or framework. But how would the framework recognize that your subclass should be used instead of a standard component?

The solution is to reduce the code that constructs components across the framework into a single factory method and let anyone override this method in addition to extending the component itself.

Let’s see how that would work. Imagine that you write an app using an open source UI framework. Your app should have round buttons, but the framework only provides square ones. You extend the standard Button class with a glorious RoundButton subclass. But now you need to tell the main UIFramework class to use the new button subclass instead of a default one.

To achieve this, you create a subclass UIWithRoundButtons from a base framework class and override its createButton method. While this method returns Button objects in the base class, you make your subclass return RoundButton objects. Now use the UIWithRoundButtons class instead of UIFramework. And that’s about it!

 Use the Factory Method when you want to save system resources by reusing existing objects instead of rebuilding them each time.

 You often experience this need when dealing with large, resource-intensive objects such as database connections, file systems, and network resources.

Let’s think about what has to be done to reuse an existing object:

First, you need to create some storage to keep track of all of the created objects.
When someone requests an object, the program should look for a free object inside that pool.
… and then return it to the client code.
If there are no free objects, the program should create a new one (and add it to the pool).
That’s a lot of code! And it must all be put into a single place so that you don’t pollute the program with duplicate code.

Probably the most obvious and convenient place where this code could be placed is the constructor of the class whose objects we’re trying to reuse. However, a constructor must always return new objects by definition. It can’t return existing instances.

Therefore, you need to have a regular method capable of creating new objects as well as reusing existing ones. That sounds very much like a factory method.

 Relations with Other Patterns
Many designs start by using Factory Method (less complicated and more customizable via subclasses) and evolve toward Abstract Factory, Prototype, or Builder (more flexible, but more complicated).

Abstract Factory classes are often based on a set of Factory Methods, but you can also use Prototype to compose the methods on these classes.

You can use Factory Method along with Iterator to let collection subclasses return different types of iterators that are compatible with the collections.

Prototype isn’t based on inheritance, so it doesn’t have its drawbacks. On the other hand, Prototype requires a complicated initialization of the cloned object. Factory Method is based on inheritance but doesn’t require an initialization step.

Factory Method is a specialization of Template Method. At the same time, a Factory Method may serve as a step in a large Template Method.

Applicability
 Use the Abstract Factory when your code needs to work with various families of related products, but you don’t want it to depend on the concrete classes of those products—they might be unknown beforehand or you simply want to allow for future extensibility.

 The Abstract Factory provides you with an interface for creating objects from each class of the product family. As long as your code creates objects via this interface, you don’t have to worry about creating the wrong variant of a product which doesn’t match the products already created by your app.

 Consider implementing the Abstract Factory when you have a class with a set of Factory Methods that blur its primary responsibility.

 In a well-designed program each class is responsible only for one thing. When a class deals with multiple product types, it may be worth extracting its factory methods into a stand-alone factory class or a full-blown Abstract Factory implementation.

Relations with Other Patterns
Many designs start by using Factory Method (less complicated and more customizable via subclasses) and evolve toward Abstract Factory, Prototype, or Builder (more flexible, but more complicated).

Builder focuses on constructing complex objects step by step. Abstract Factory specializes in creating families of related objects. Abstract Factory returns the product immediately, whereas Builder lets you run some additional construction steps before fetching the product.

Abstract Factory classes are often based on a set of Factory Methods, but you can also use Prototype to compose the methods on these classes.

Abstract Factory can serve as an alternative to Facade when you only want to hide the way the subsystem objects are created from the client code.

You can use Abstract Factory along with Bridge. This pairing is useful when some abstractions defined by Bridge can only work with specific implementations. In this case, Abstract Factory can encapsulate these relations and hide the complexity from the client code.

Abstract Factories, Builders and Prototypes can all be implemented as Singletons.

Applicability
 Use the Builder pattern to get rid of a “telescoping constructor”.

 Say you have a constructor with ten optional parameters. Calling such a beast is very inconvenient; therefore, you overload the constructor and create several shorter versions with fewer parameters. These constructors still refer to the main one, passing some default values into any omitted parameters.

class Pizza {
    Pizza(int size) { ... }
    Pizza(int size, boolean cheese) { ... }
    Pizza(int size, boolean cheese, boolean pepperoni) { ... }
    // ...
Creating such a monster is only possible in languages that support method overloading, such as C# or Java.

The Builder pattern lets you build objects step by step, using only those steps that you really need. After implementing the pattern, you don’t have to cram dozens of parameters into your constructors anymore.

 Use the Builder pattern when you want your code to be able to create different representations of some product (for example, stone and wooden houses).

 The Builder pattern can be applied when construction of various representations of the product involves similar steps that differ only in the details.

The base builder interface defines all possible construction steps, and concrete builders implement these steps to construct particular representations of the product. Meanwhile, the director class guides the order of construction.

 Use the Builder to construct Composite trees or other complex objects.

 The Builder pattern lets you construct products step-by-step. You could defer execution of some steps without breaking the final product. You can even call steps recursively, which comes in handy when you need to build an object tree.

A builder doesn’t expose the unfinished product while running construction steps. This prevents the client code from fetching an incomplete result.

Relations with Other Patterns
Many designs start by using Factory Method (less complicated and more customizable via subclasses) and evolve toward Abstract Factory, Prototype, or Builder (more flexible, but more complicated).

Builder focuses on constructing complex objects step by step. Abstract Factory specializes in creating families of related objects. Abstract Factory returns the product immediately, whereas Builder lets you run some additional construction steps before fetching the product.

You can use Builder when creating complex Composite trees because you can program its construction steps to work recursively.

You can combine Builder with Bridge: the director class plays the role of the abstraction, while different builders act as implementations.

Abstract Factories, Builders and Prototypes can all be implemented as Singletons.

Applicability
 Use the Prototype pattern when your code shouldn’t depend on the concrete classes of objects that you need to copy.

 This happens a lot when your code works with objects passed to you from 3rd-party code via some interface. The concrete classes of these objects are unknown, and you couldn’t depend on them even if you wanted to.

The Prototype pattern provides the client code with a general interface for working with all objects that support cloning. This interface makes the client code independent from the concrete classes of objects that it clones.

 Use the pattern when you want to reduce the number of subclasses that only differ in the way they initialize their respective objects.

 Suppose you have a complex class that requires a laborious configuration before it can be used. There are several common ways to configure this class, and this code is scattered through your app. To reduce the duplication, you create several subclasses and put every common configuration code into their constructors. You solved the duplication problem, but now you have lots of dummy subclasses.

The Prototype pattern lets you use a set of pre-built objects configured in various ways as prototypes. Instead of instantiating a subclass that matches some configuration, the client can simply look for an appropriate prototype and clone it.

Relations with Other Patterns
Many designs start by using Factory Method (less complicated and more customizable via subclasses) and evolve toward Abstract Factory, Prototype, or Builder (more flexible, but more complicated).

Abstract Factory classes are often based on a set of Factory Methods, but you can also use Prototype to compose the methods on these classes.

Prototype can help when you need to save copies of Commands into history.

Designs that make heavy use of Composite and Decorator can often benefit from using Prototype. Applying the pattern lets you clone complex structures instead of re-constructing them from scratch.

Prototype isn’t based on inheritance, so it doesn’t have its drawbacks. On the other hand, Prototype requires a complicated initialization of the cloned object. Factory Method is based on inheritance but doesn’t require an initialization step.

Sometimes Prototype can be a simpler alternative to Memento. This works if the object, the state of which you want to store in the history, is fairly straightforward and doesn’t have links to external resources, or the links are easy to re-establish.

Abstract Factories, Builders and Prototypes can all be implemented as Singletons.

Applicability
 Use the Singleton pattern when a class in your program should have just a single instance available to all clients; for example, a single database object shared by different parts of the program.

 The Singleton pattern disables all other means of creating objects of a class except for the special creation method. This method either creates a new object or returns an existing one if it has already been created.

 Use the Singleton pattern when you need stricter control over global variables.

 Unlike global variables, the Singleton pattern guarantees that there’s just one instance of a class. Nothing, except for the Singleton class itself, can replace the cached instance.

Note that you can always adjust this limitation and allow creating any number of Singleton instances. The only piece of code that needs changing is the body of the getInstance method.

Relations with Other Patterns
A Facade class can often be transformed into a Singleton since a single facade object is sufficient in most cases.

Flyweight would resemble Singleton if you somehow managed to reduce all shared states of the objects to just one flyweight object. But there are two fundamental differences between these patterns:

There should be only one Singleton instance, whereas a Flyweight class can have multiple instances with different intrinsic states.
The Singleton object can be mutable. Flyweight objects are immutable.
Abstract Factories, Builders and Prototypes can all be implemented as Singletons.

Applicability
 Use the Adapter class when you want to use some existing class, but its interface isn’t compatible with the rest of your code.

 The Adapter pattern lets you create a middle-layer class that serves as a translator between your code and a legacy class, a 3rd-party class or any other class with a weird interface.

 Use the pattern when you want to reuse several existing subclasses that lack some common functionality that can’t be added to the superclass.

 You could extend each subclass and put the missing functionality into new child classes. However, you’ll need to duplicate the code across all of these new classes, which smells really bad.

The much more elegant solution would be to put the missing functionality into an adapter class. Then you would wrap objects with missing features inside the adapter, gaining needed features dynamically. For this to work, the target classes must have a common interface, and the adapter’s field should follow that interface. This approach looks very similar to the Decorator pattern.

Relations with Other Patterns
Bridge is usually designed up-front, letting you develop parts of an application independently of each other. On the other hand, Adapter is commonly used with an existing app to make some otherwise-incompatible classes work together nicely.

Adapter provides a completely different interface for accessing an existing object. On the other hand, with the Decorator pattern the interface either stays the same or gets extended. In addition, Decorator supports recursive composition, which isn’t possible when you use Adapter.

With Adapter you access an existing object via different interface. With Proxy, the interface stays the same. With Decorator you access the object via an enhanced interface.

Facade defines a new interface for existing objects, whereas Adapter tries to make the existing interface usable. Adapter usually wraps just one object, while Facade works with an entire subsystem of objects.

Bridge, State, Strategy (and to some degree Adapter) have very similar structures. Indeed, all of these patterns are based on composition, which is delegating work to other objects. However, they all solve different problems. A pattern isn’t just a recipe for structuring your code in a specific way. It can also communicate to other developers the problem the pattern solves.

Applicability
 Use the Bridge pattern when you want to divide and organize a monolithic class that has several variants of some functionality (for example, if the class can work with various database servers).

 The bigger a class becomes, the harder it is to figure out how it works, and the longer it takes to make a change. The changes made to one of the variations of functionality may require making changes across the whole class, which often results in making errors or not addressing some critical side effects.

The Bridge pattern lets you split the monolithic class into several class hierarchies. After this, you can change the classes in each hierarchy independently of the classes in the others. This approach simplifies code maintenance and minimizes the risk of breaking existing code.

 Use the pattern when you need to extend a class in several orthogonal (independent) dimensions.

 The Bridge suggests that you extract a separate class hierarchy for each of the dimensions. The original class delegates the related work to the objects belonging to those hierarchies instead of doing everything on its own.

 Use the Bridge if you need to be able to switch implementations at runtime.

 Although it’s optional, the Bridge pattern lets you replace the implementation object inside the abstraction. It’s as easy as assigning a new value to a field.

By the way, this last item is the main reason why so many people confuse the Bridge with the Strategy pattern. Remember that a pattern is more than just a certain way to structure your classes. It may also communicate intent and a problem being addressed.

Relations with Other Patterns
Bridge is usually designed up-front, letting you develop parts of an application independently of each other. On the other hand, Adapter is commonly used with an existing app to make some otherwise-incompatible classes work together nicely.

Bridge, State, Strategy (and to some degree Adapter) have very similar structures. Indeed, all of these patterns are based on composition, which is delegating work to other objects. However, they all solve different problems. A pattern isn’t just a recipe for structuring your code in a specific way. It can also communicate to other developers the problem the pattern solves.

You can use Abstract Factory along with Bridge. This pairing is useful when some abstractions defined by Bridge can only work with specific implementations. In this case, Abstract Factory can encapsulate these relations and hide the complexity from the client code.

You can combine Builder with Bridge: the director class plays the role of the abstraction, while different builders act as implementations.

Applicability
 Use the Composite pattern when you have to implement a tree-like object structure.

 The Composite pattern provides you with two basic element types that share a common interface: simple leaves and complex containers. A container can be composed of both leaves and other containers. This lets you construct a nested recursive object structure that resembles a tree.

 Use the pattern when you want the client code to treat both simple and complex elements uniformly.

 All elements defined by the Composite pattern share a common interface. Using this interface, the client doesn’t have to worry about the concrete class of the objects it works with.

Relations with Other Patterns
You can use Builder when creating complex Composite trees because you can program its construction steps to work recursively.

Chain of Responsibility is often used in conjunction with Composite. In this case, when a leaf component gets a request, it may pass it through the chain of all of the parent components down to the root of the object tree.

You can use Iterators to traverse Composite trees.

You can use Visitor to execute an operation over an entire Composite tree.

You can implement shared leaf nodes of the Composite tree as Flyweights to save some RAM.

Composite and Decorator have similar structure diagrams since both rely on recursive composition to organize an open-ended number of objects.

A Decorator is like a Composite but only has one child component. There’s another significant difference: Decorator adds additional responsibilities to the wrapped object, while Composite just “sums up” its children’s results.

However, the patterns can also cooperate: you can use Decorator to extend the behavior of a specific object in the Composite tree.

Designs that make heavy use of Composite and Decorator can often benefit from using Prototype. Applying the pattern lets you clone complex structures instead of re-constructing them from scratch.

Applicability
 Use the Decorator pattern when you need to be able to assign extra behaviors to objects at runtime without breaking the code that uses these objects.

 The Decorator lets you structure your business logic into layers, create a decorator for each layer and compose objects with various combinations of this logic at runtime. The client code can treat all these objects in the same way, since they all follow a common interface.

 Use the pattern when it’s awkward or not possible to extend an object’s behavior using inheritance.

 Many programming languages have the final keyword that can be used to prevent further extension of a class. For a final class, the only way to reuse the existing behavior would be to wrap the class with your own wrapper, using the Decorator pattern.

Relations with Other Patterns
Adapter provides a completely different interface for accessing an existing object. On the other hand, with the Decorator pattern the interface either stays the same or gets extended. In addition, Decorator supports recursive composition, which isn’t possible when you use Adapter.

With Adapter you access an existing object via different interface. With Proxy, the interface stays the same. With Decorator you access the object via an enhanced interface.

Chain of Responsibility and Decorator have very similar class structures. Both patterns rely on recursive composition to pass the execution through a series of objects. However, there are several crucial differences.

The CoR handlers can execute arbitrary operations independently of each other. They can also stop passing the request further at any point. On the other hand, various Decorators can extend the object’s behavior while keeping it consistent with the base interface. In addition, decorators aren’t allowed to break the flow of the request.

Composite and Decorator have similar structure diagrams since both rely on recursive composition to organize an open-ended number of objects.

A Decorator is like a Composite but only has one child component. There’s another significant difference: Decorator adds additional responsibilities to the wrapped object, while Composite just “sums up” its children’s results.

However, the patterns can also cooperate: you can use Decorator to extend the behavior of a specific object in the Composite tree.

Designs that make heavy use of Composite and Decorator can often benefit from using Prototype. Applying the pattern lets you clone complex structures instead of re-constructing them from scratch.

Decorator lets you change the skin of an object, while Strategy lets you change the guts.

Decorator and Proxy have similar structures, but very different intents. Both patterns are built on the composition principle, where one object is supposed to delegate some of the work to another. The difference is that a Proxy usually manages the life cycle of its service object on its own, whereas the composition of Decorators is always controlled by the client.

Applicability
 Use the Facade pattern when you need to have a limited but straightforward interface to a complex subsystem.

 Often, subsystems get more complex over time. Even applying design patterns typically leads to creating more classes. A subsystem may become more flexible and easier to reuse in various contexts, but the amount of configuration and boilerplate code it demands from a client grows ever larger. The Facade attempts to fix this problem by providing a shortcut to the most-used features of the subsystem which fit most client requirements.

 Use the Facade when you want to structure a subsystem into layers.

 Create facades to define entry points to each level of a subsystem. You can reduce coupling between multiple subsystems by requiring them to communicate only through facades.

For example, let’s return to our video conversion framework. It can be broken down into two layers: video- and audio-related. For each layer, you can create a facade and then make the classes of each layer communicate with each other via those facades. This approach looks very similar to the Mediator pattern.

Relations with Other Patterns
Facade defines a new interface for existing objects, whereas Adapter tries to make the existing interface usable. Adapter usually wraps just one object, while Facade works with an entire subsystem of objects.

Abstract Factory can serve as an alternative to Facade when you only want to hide the way the subsystem objects are created from the client code.

Flyweight shows how to make lots of little objects, whereas Facade shows how to make a single object that represents an entire subsystem.

Facade and Mediator have similar jobs: they try to organize collaboration between lots of tightly coupled classes.

Facade defines a simplified interface to a subsystem of objects, but it doesn’t introduce any new functionality. The subsystem itself is unaware of the facade. Objects within the subsystem can communicate directly.
Mediator centralizes communication between components of the system. The components only know about the mediator object and don’t communicate directly.
A Facade class can often be transformed into a Singleton since a single facade object is sufficient in most cases.

Facade is similar to Proxy in that both buffer a complex entity and initialize it on its own. Unlike Facade, Proxy has the same interface as its service object, which makes them interchangeable.

Applicability
 Use the Flyweight pattern only when your program must support a huge number of objects which barely fit into available RAM.

 The benefit of applying the pattern depends heavily on how and where it’s used. It’s most useful when:

an application needs to spawn a huge number of similar objects
this drains all available RAM on a target device
the objects contain duplicate states which can be extracted and shared between multiple objects

Relations with Other Patterns
You can implement shared leaf nodes of the Composite tree as Flyweights to save some RAM.

Flyweight shows how to make lots of little objects, whereas Facade shows how to make a single object that represents an entire subsystem.

Flyweight would resemble Singleton if you somehow managed to reduce all shared states of the objects to just one flyweight object. But there are two fundamental differences between these patterns:

There should be only one Singleton instance, whereas a Flyweight class can have multiple instances with different intrinsic states.
The Singleton object can be mutable. Flyweight objects are immutable.

Applicability
There are dozens of ways to utilize the Proxy pattern. Let’s go over the most popular uses.

 Lazy initialization (virtual proxy). This is when you have a heavyweight service object that wastes system resources by being always up, even though you only need it from time to time.

 Instead of creating the object when the app launches, you can delay the object’s initialization to a time when it’s really needed.

 Access control (protection proxy). This is when you want only specific clients to be able to use the service object; for instance, when your objects are crucial parts of an operating system and clients are various launched applications (including malicious ones).

 The proxy can pass the request to the service object only if the client’s credentials match some criteria.

 Local execution of a remote service (remote proxy). This is when the service object is located on a remote server.

 In this case, the proxy passes the client request over the network, handling all of the nasty details of working with the network.

 Logging requests (logging proxy). This is when you want to keep a history of requests to the service object.

 The proxy can log each request before passing it to the service.

 Caching request results (caching proxy). This is when you need to cache results of client requests and manage the life cycle of this cache, especially if results are quite large.

 The proxy can implement caching for recurring requests that always yield the same results. The proxy may use the parameters of requests as the cache keys.

 Smart reference. This is when you need to be able to dismiss a heavyweight object once there are no clients that use it.

 The proxy can keep track of clients that obtained a reference to the service object or its results. From time to time, the proxy may go over the clients and check whether they are still active. If the client list gets empty, the proxy might dismiss the service object and free the underlying system resources.

The proxy can also track whether the client had modified the service object. Then the unchanged objects may be reused by other clients.

Relations with Other Patterns
With Adapter you access an existing object via different interface. With Proxy, the interface stays the same. With Decorator you access the object via an enhanced interface.

Facade is similar to Proxy in that both buffer a complex entity and initialize it on its own. Unlike Facade, Proxy has the same interface as its service object, which makes them interchangeable.

Decorator and Proxy have similar structures, but very different intents. Both patterns are built on the composition principle, where one object is supposed to delegate some of the work to another. The difference is that a Proxy usually manages the life cycle of its service object on its own, whereas the composition of Decorators is always controlled by the client.

Applicability
 Use the Chain of Responsibility pattern when your program is expected to process different kinds of requests in various ways, but the exact types of requests and their sequences are unknown beforehand.

 The pattern lets you link several handlers into one chain and, upon receiving a request, “ask” each handler whether it can process it. This way all handlers get a chance to process the request.

 Use the pattern when it’s essential to execute several handlers in a particular order.

 Since you can link the handlers in the chain in any order, all requests will get through the chain exactly as you planned.

 Use the CoR pattern when the set of handlers and their order are supposed to change at runtime.

 If you provide setters for a reference field inside the handler classes, you’ll be able to insert, remove or reorder handlers dynamically.

Relations with Other Patterns
Chain of Responsibility, Command, Mediator and Observer address various ways of connecting senders and receivers of requests:

Chain of Responsibility passes a request sequentially along a dynamic chain of potential receivers until one of them handles it.
Command establishes unidirectional connections between senders and receivers.
Mediator eliminates direct connections between senders and receivers, forcing them to communicate indirectly via a mediator object.
Observer lets receivers dynamically subscribe to and unsubscribe from receiving requests.
Chain of Responsibility is often used in conjunction with Composite. In this case, when a leaf component gets a request, it may pass it through the chain of all of the parent components down to the root of the object tree.

Handlers in Chain of Responsibility can be implemented as Commands. In this case, you can execute a lot of different operations over the same context object, represented by a request.

However, there’s another approach, where the request itself is a Command object. In this case, you can execute the same operation in a series of different contexts linked into a chain.

Chain of Responsibility and Decorator have very similar class structures. Both patterns rely on recursive composition to pass the execution through a series of objects. However, there are several crucial differences.

The CoR handlers can execute arbitrary operations independently of each other. They can also stop passing the request further at any point. On the other hand, various Decorators can extend the object’s behavior while keeping it consistent with the base interface. In addition, decorators aren’t allowed to break the flow of the request.

Applicability
 Use the Command pattern when you want to parameterize objects with operations.

 The Command pattern can turn a specific method call into a stand-alone object. This change opens up a lot of interesting uses: you can pass commands as method arguments, store them inside other objects, switch linked commands at runtime, etc.

Here’s an example: you’re developing a GUI component such as a context menu, and you want your users to be able to configure menu items that trigger operations when an end user clicks an item.

 Use the Command pattern when you want to queue operations, schedule their execution, or execute them remotely.

 As with any other object, a command can be serialized, which means converting it to a string that can be easily written to a file or a database. Later, the string can be restored as the initial command object. Thus, you can delay and schedule command execution. But there’s even more! In the same way, you can queue, log or send commands over the network.

 Use the Command pattern when you want to implement reversible operations.

 Although there are many ways to implement undo/redo, the Command pattern is perhaps the most popular of all.

To be able to revert operations, you need to implement the history of performed operations. The command history is a stack that contains all executed command objects along with related backups of the application’s state.

This method has two drawbacks. First, it isn’t that easy to save an application’s state because some of it can be private. This problem can be mitigated with the Memento pattern.

Second, the state backups may consume quite a lot of RAM. Therefore, sometimes you can resort to an alternative implementation: instead of restoring the past state, the command performs the inverse operation. The reverse operation also has a price: it may turn out to be hard or even impossible to implement.

Relations with Other Patterns
Chain of Responsibility, Command, Mediator and Observer address various ways of connecting senders and receivers of requests:

Chain of Responsibility passes a request sequentially along a dynamic chain of potential receivers until one of them handles it.
Command establishes unidirectional connections between senders and receivers.
Mediator eliminates direct connections between senders and receivers, forcing them to communicate indirectly via a mediator object.
Observer lets receivers dynamically subscribe to and unsubscribe from receiving requests.
Handlers in Chain of Responsibility can be implemented as Commands. In this case, you can execute a lot of different operations over the same context object, represented by a request.

However, there’s another approach, where the request itself is a Command object. In this case, you can execute the same operation in a series of different contexts linked into a chain.

You can use Command and Memento together when implementing “undo”. In this case, commands are responsible for performing various operations over a target object, while mementos save the state of that object just before a command gets executed.

Command and Strategy may look similar because you can use both to parameterize an object with some action. However, they have very different intents.

You can use Command to convert any operation into an object. The operation’s parameters become fields of that object. The conversion lets you defer execution of the operation, queue it, store the history of commands, send commands to remote services, etc.

On the other hand, Strategy usually describes different ways of doing the same thing, letting you swap these algorithms within a single context class.

Prototype can help when you need to save copies of Commands into history.

You can treat Visitor as a powerful version of the Command pattern. Its objects can execute operations over various objects of different classes.

Applicability
 Use the Iterator pattern when your collection has a complex data structure under the hood, but you want to hide its complexity from clients (either for convenience or security reasons).

 The iterator encapsulates the details of working with a complex data structure, providing the client with several simple methods of accessing the collection elements. While this approach is very convenient for the client, it also protects the collection from careless or malicious actions which the client would be able to perform if working with the collection directly.

 Use the pattern to reduce duplication of the traversal code across your app.

 The code of non-trivial iteration algorithms tends to be very bulky. When placed within the business logic of an app, it may blur the responsibility of the original code and make it less maintainable. Moving the traversal code to designated iterators can help you make the code of the application more lean and clean.

 Use the Iterator when you want your code to be able to traverse different data structures or when types of these structures are unknown beforehand.

 The pattern provides a couple of generic interfaces for both collections and iterators. Given that your code now uses these interfaces, it’ll still work if you pass it various kinds of collections and iterators that implement these interfaces.

Relations with Other Patterns
You can use Iterators to traverse Composite trees.

You can use Factory Method along with Iterator to let collection subclasses return different types of iterators that are compatible with the collections.

You can use Memento along with Iterator to capture the current iteration state and roll it back if necessary.

You can use Visitor along with Iterator to traverse a complex data structure and execute some operation over its elements, even if they all have different classes.

Applicability
 Use the Mediator pattern when it’s hard to change some of the classes because they are tightly coupled to a bunch of other classes.

 The pattern lets you extract all the relationships between classes into a separate class, isolating any changes to a specific component from the rest of the components.

 Use the pattern when you can’t reuse a component in a different program because it’s too dependent on other components.

 After you apply the Mediator, individual components become unaware of the other components. They could still communicate with each other, albeit indirectly, through a mediator object. To reuse a component in a different app, you need to provide it with a new mediator class.

 Use the Mediator when you find yourself creating tons of component subclasses just to reuse some basic behavior in various contexts.

 Since all relations between components are contained within the mediator, it’s easy to define entirely new ways for these components to collaborate by introducing new mediator classes, without having to change the components themselves.

 Relations with Other Patterns
Chain of Responsibility, Command, Mediator and Observer address various ways of connecting senders and receivers of requests:

Chain of Responsibility passes a request sequentially along a dynamic chain of potential receivers until one of them handles it.
Command establishes unidirectional connections between senders and receivers.
Mediator eliminates direct connections between senders and receivers, forcing them to communicate indirectly via a mediator object.
Observer lets receivers dynamically subscribe to and unsubscribe from receiving requests.
Facade and Mediator have similar jobs: they try to organize collaboration between lots of tightly coupled classes.

Facade defines a simplified interface to a subsystem of objects, but it doesn’t introduce any new functionality. The subsystem itself is unaware of the facade. Objects within the subsystem can communicate directly.
Mediator centralizes communication between components of the system. The components only know about the mediator object and don’t communicate directly.
The difference between Mediator and Observer is often elusive. In most cases, you can implement either of these patterns; but sometimes you can apply both simultaneously. Let’s see how we can do that.

The primary goal of Mediator is to eliminate mutual dependencies among a set of system components. Instead, these components become dependent on a single mediator object. The goal of Observer is to establish dynamic one-way connections between objects, where some objects act as subordinates of others.

There’s a popular implementation of the Mediator pattern that relies on Observer. The mediator object plays the role of publisher, and the components act as subscribers which subscribe to and unsubscribe from the mediator’s events. When Mediator is implemented this way, it may look very similar to Observer.

When you’re confused, remember that you can implement the Mediator pattern in other ways. For example, you can permanently link all the components to the same mediator object. This implementation won’t resemble Observer but will still be an instance of the Mediator pattern.

Now imagine a program where all components have become publishers, allowing dynamic connections between each other. There won’t be a centralized mediator object, only a distributed set of observers.

Applicability
 Use the Memento pattern when you want to produce snapshots of the object’s state to be able to restore a previous state of the object.

 The Memento pattern lets you make full copies of an object’s state, including private fields, and store them separately from the object. While most people remember this pattern thanks to the “undo” use case, it’s also indispensable when dealing with transactions (i.e., if you need to roll back an operation on error).

 Use the pattern when direct access to the object’s fields/getters/setters violates its encapsulation.

 The Memento makes the object itself responsible for creating a snapshot of its state. No other object can read the snapshot, making the original object’s state data safe and secure.

 Relations with Other Patterns
You can use Command and Memento together when implementing “undo”. In this case, commands are responsible for performing various operations over a target object, while mementos save the state of that object just before a command gets executed.

You can use Memento along with Iterator to capture the current iteration state and roll it back if necessary.

Sometimes Prototype can be a simpler alternative to Memento. This works if the object, the state of which you want to store in the history, is fairly straightforward and doesn’t have links to external resources, or the links are easy to re-establish.

Applicability
 Use the Observer pattern when changes to the state of one object may require changing other objects, and the actual set of objects is unknown beforehand or changes dynamically.

 You can often experience this problem when working with classes of the graphical user interface. For example, you created custom button classes, and you want to let the clients hook some custom code to your buttons so that it fires whenever a user presses a button.

The Observer pattern lets any object that implements the subscriber interface subscribe for event notifications in publisher objects. You can add the subscription mechanism to your buttons, letting the clients hook up their custom code via custom subscriber classes.

 Use the pattern when some objects in your app must observe others, but only for a limited time or in specific cases.

 The subscription list is dynamic, so subscribers can join or leave the list whenever they need to.

 Relations with Other Patterns
Chain of Responsibility, Command, Mediator and Observer address various ways of connecting senders and receivers of requests:

Chain of Responsibility passes a request sequentially along a dynamic chain of potential receivers until one of them handles it.
Command establishes unidirectional connections between senders and receivers.
Mediator eliminates direct connections between senders and receivers, forcing them to communicate indirectly via a mediator object.
Observer lets receivers dynamically subscribe to and unsubscribe from receiving requests.
The difference between Mediator and Observer is often elusive. In most cases, you can implement either of these patterns; but sometimes you can apply both simultaneously. Let’s see how we can do that.

The primary goal of Mediator is to eliminate mutual dependencies among a set of system components. Instead, these components become dependent on a single mediator object. The goal of Observer is to establish dynamic one-way connections between objects, where some objects act as subordinates of others.

There’s a popular implementation of the Mediator pattern that relies on Observer. The mediator object plays the role of publisher, and the components act as subscribers which subscribe to and unsubscribe from the mediator’s events. When Mediator is implemented this way, it may look very similar to Observer.

When you’re confused, remember that you can implement the Mediator pattern in other ways. For example, you can permanently link all the components to the same mediator object. This implementation won’t resemble Observer but will still be an instance of the Mediator pattern.

Now imagine a program where all components have become publishers, allowing dynamic connections between each other. There won’t be a centralized mediator object, only a distributed set of observers.

Applicability
 Use the State pattern when you have an object that behaves differently depending on its current state, the number of states is enormous, and the state-specific code changes frequently.

 The pattern suggests that you extract all state-specific code into a set of distinct classes. As a result, you can add new states or change existing ones independently of each other, reducing the maintenance cost.

 Use the pattern when you have a class polluted with massive conditionals that alter how the class behaves according to the current values of the class’s fields.

 The State pattern lets you extract branches of these conditionals into methods of corresponding state classes. While doing so, you can also clean temporary fields and helper methods involved in state-specific code out of your main class.

 Use State when you have a lot of duplicate code across similar states and transitions of a condition-based state machine.

 The State pattern lets you compose hierarchies of state classes and reduce duplication by extracting common code into abstract base classes.


Relations with Other Patterns
Bridge, State, Strategy (and to some degree Adapter) have very similar structures. Indeed, all of these patterns are based on composition, which is delegating work to other objects. However, they all solve different problems. A pattern isn’t just a recipe for structuring your code in a specific way. It can also communicate to other developers the problem the pattern solves.

State can be considered as an extension of Strategy. Both patterns are based on composition: they change the behavior of the context by delegating some work to helper objects. Strategy makes these objects completely independent and unaware of each other. However, State doesn’t restrict dependencies between concrete states, letting them alter the state of the context at will.

Applicability
 Use the Strategy pattern when you want to use different variants of an algorithm within an object and be able to switch from one algorithm to another during runtime.

 The Strategy pattern lets you indirectly alter the object’s behavior at runtime by associating it with different sub-objects which can perform specific sub-tasks in different ways.

 Use the Strategy when you have a lot of similar classes that only differ in the way they execute some behavior.

 The Strategy pattern lets you extract the varying behavior into a separate class hierarchy and combine the original classes into one, thereby reducing duplicate code.

 Use the pattern to isolate the business logic of a class from the implementation details of algorithms that may not be as important in the context of that logic.

 The Strategy pattern lets you isolate the code, internal data, and dependencies of various algorithms from the rest of the code. Various clients get a simple interface to execute the algorithms and switch them at runtime.

 Use the pattern when your class has a massive conditional statement that switches between different variants of the same algorithm.

 The Strategy pattern lets you do away with such a conditional by extracting all algorithms into separate classes, all of which implement the same interface. The original object delegates execution to one of these objects, instead of implementing all variants of the algorithm.

Relations with Other Patterns
Bridge, State, Strategy (and to some degree Adapter) have very similar structures. Indeed, all of these patterns are based on composition, which is delegating work to other objects. However, they all solve different problems. A pattern isn’t just a recipe for structuring your code in a specific way. It can also communicate to other developers the problem the pattern solves.

Command and Strategy may look similar because you can use both to parameterize an object with some action. However, they have very different intents.

You can use Command to convert any operation into an object. The operation’s parameters become fields of that object. The conversion lets you defer execution of the operation, queue it, store the history of commands, send commands to remote services, etc.

On the other hand, Strategy usually describes different ways of doing the same thing, letting you swap these algorithms within a single context class.

Decorator lets you change the skin of an object, while Strategy lets you change the guts.

Template Method is based on inheritance: it lets you alter parts of an algorithm by extending those parts in subclasses. Strategy is based on composition: you can alter parts of the object’s behavior by supplying it with different strategies that correspond to that behavior. Template Method works at the class level, so it’s static. Strategy works on the object level, letting you switch behaviors at runtime.

State can be considered as an extension of Strategy. Both patterns are based on composition: they change the behavior of the context by delegating some work to helper objects. Strategy makes these objects completely independent and unaware of each other. However, State doesn’t restrict dependencies between concrete states, letting them alter the state of the context at will.

Applicability
 Use the Template Method pattern when you want to let clients extend only particular steps of an algorithm, but not the whole algorithm or its structure.

 The Template Method lets you turn a monolithic algorithm into a series of individual steps which can be easily extended by subclasses while keeping intact the structure defined in a superclass.

 Use the pattern when you have several classes that contain almost identical algorithms with some minor differences. As a result, you might need to modify all classes when the algorithm changes.

 When you turn such an algorithm into a template method, you can also pull up the steps with similar implementations into a superclass, eliminating code duplication. Code that varies between subclasses can remain in subclasses.

Relations with Other Patterns
Factory Method is a specialization of Template Method. At the same time, a Factory Method may serve as a step in a large Template Method.

Template Method is based on inheritance: it lets you alter parts of an algorithm by extending those parts in subclasses. Strategy is based on composition: you can alter parts of the object’s behavior by supplying it with different strategies that correspond to that behavior. Template Method works at the class level, so it’s static. Strategy works on the object level, letting you switch behaviors at runtime.

Applicability
 Use the Visitor when you need to perform an operation on all elements of a complex object structure (for example, an object tree).

 The Visitor pattern lets you execute an operation over a set of objects with different classes by having a visitor object implement several variants of the same operation, which correspond to all target classes.

 Use the Visitor to clean up the business logic of auxiliary behaviors.

 The pattern lets you make the primary classes of your app more focused on their main jobs by extracting all other behaviors into a set of visitor classes.

 Use the pattern when a behavior makes sense only in some classes of a class hierarchy, but not in others.

 You can extract this behavior into a separate visitor class and implement only those visiting methods that accept objects of relevant classes, leaving the rest empty.

Relations with Other Patterns
You can treat Visitor as a powerful version of the Command pattern. Its objects can execute operations over various objects of different classes.

You can use Visitor to execute an operation over an entire Composite tree.

You can use Visitor along with Iterator to traverse a complex data structure and execute some operation over its elements, even if they all have different classes.

