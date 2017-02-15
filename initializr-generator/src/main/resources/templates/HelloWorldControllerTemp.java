package ${packageName};
 

import java.util.concurrent.atomic.AtomicLong;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;


@Controller
@RequestMapping("/${applicationName}")
public class HelloWorldController {

    private static final String template = "Hello, %s!";

	
    @RequestMapping(value="/hello", method=RequestMethod.GET)
    @ResponseBody
    String  sayHello2(String name) {
		return "Hello from ${applicationName} ! ";
    }	

}
