///////////////////////////////////////////////////////////////////////////
//
// The code for the green team
// ===========================
//
///////////////////////////////////////////////////////////////////////////

class RedTeam extends Team {
  
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green bases
//
///////////////////////////////////////////////////////////////////////////
class RedBase extends Base {

  // MESSAGES
  final int MY_CUSTOM_MSG = 5;
  final int DEFEND_AT_XY = 12;
  final int TARGET_LAUNCHER_AT_XY = 13;

  // STRATEGY PARAMETERS
  final int KEEP_ENERGY_FOR_EMERGENCY = 10000;

  // Step 1 specifics
  final int WILD_BURGER_TO_FARM = 1000;

  // Step 2 specifics
  final int HARVESTERS_TO_CREATE = 50;
  final float BURGER_RATIO_FOR_BASE = 20.0/100.0;
  final int ENERGY_FOR_ARMAGGEDON = 1000000;
  final int LAUNCHER_FOR_ARMAGGEDON = 50;

  // Step 3 specifics
  final int LAUNCHER_TO_CREATE = 100;


  //
  // constructor
  // ===========
  //
  RedBase(PVector p, color c, Team t, int no) {
    super(p, c, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the base
  //
  void setup() {
    // creates an explorer
    newExplorer();
    // create 3 more explorers and 8 harvesters later
    brain[5].x = 8;
    brain[5].z = 3;
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {

    // Base brain :
    // 0:
    // 1: Step 1 specifics:  
    // 2: Step 2 specifics: 
    // 3: Step 3 specifics:  
    // 4:
    // 5: Robot creation :  x -> Harvester   y -> Rocket Launcher   z -> Explorer
    // 6:
    // 7:
    // 8: x -> wild burgers collected during step 1   y -> missileLauncher created during step 2
    // 9: x -> current state    y -> emergency ?

    determineCurrentState();

    warnAboutState();
    
    switch ((int) brain[9].x)
    {
      case 0 : baseEmergencyBehavior(); break;
      case 1 : baseBehaviorStep1(); break;
      case 2 : baseBehaviorStep2(); break;
      case 3 : baseBehaviorStep3(); break;
      default : break;	
    }
  }

  //// DETERMINATION OF THE CURRENT GAME STATE ////
  // -> State stored in brain[9]
  // brain[9].x = 0 -> Emergency  ;  n -> Step n
  // brain[9].y = ( 0 -> No emergency ; 1 -> Emergency : Attacked by enemy)
  // Step 1 : Exploration + Burger Collection
  // Step 2 : Power Farm
  // Step 3 : Armaggedon
  void determineCurrentState()
  {
    // Determine if a base is currently attacked
    ArrayList enemyRobots = perceiveRobots(ennemy, LAUNCHER);
    if (enemyRobots != null)
    {
      if (enemyRobots.size() >= 5) brain[9].y = 1;
    }

    // if no emergency
    if (brain[9].y == 0)
    {
      // we are in step 1 by default
      brain[9].x = 1;

      // go to step 2 if we collected enough wild burgers
      if (brain[8].x >= WILD_BURGER_TO_FARM) brain[9].x = 2;

      // if we are in step 2
      if (brain[9].x == 2)
      {
        // go to step 3 if we prepared enough missile launchers and we have enough energy
        if (brain[8].y >= LAUNCHER_FOR_ARMAGGEDON && energy >= ENERGY_FOR_ARMAGGEDON ) brain[9].x = 3; 
      }
    }
    // if a base is currently attacked
    else if (brain[9].y == 1)
    {
      brain[9].x = 0;
    }
  }

  // Warn all the robots in range about the current state
  void warnAboutState()
  {
    ArrayList<Robot> friendlyRobots = perceiveRobots(friend);
    if (friendlyRobots != null)
    {
      for (Robot friend : friendlyRobots)
      {
        friend.brain[4].x = brain[9].x;
      }
    }
  }

  //// Step 1 ////
  // 
  //
  //
  //
  //
  void baseBehaviorStep1()
  {
    // handle received messages 
      handleMessagesStep1();

      //// ROBOT CREATION
      robotCreationStep1();

      // creates new bullets and fafs if the stock is low and enought energy
      manageMissiles();

      // if ennemy rocket launcher in the area of perception
      selfDefense();
  }

  void handleMessagesStep1()
  {
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == ASK_FOR_ENERGY) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0]) {
          // gives the requested amount of energy only if at least 1000 units of energy left after
          giveEnergy(msg.agent, msg.args[0]);
        }
      } else if (msg.type == ASK_FOR_BULLETS) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0] * bulletCost) {
          // gives the requested amount of bullets only if at least 1000 units of energy left after
          giveBullets(msg.agent, msg.args[0]);
        }
      }
    }
    // clear the message queue
    flushMessages();
  }



  //// ROBOT CREATION ////
  //
  // During Step 1 the priority of robot creation is rocket launchers
  // (if there is a need), then explorers and finally harvesters
  //
  // Rocket launchers are only created if there is no rocket launcher already to defend the base
  // and there is an ennemy rocket launcher attacking, or at a rate of 10%
  // 
  // Explorers are created in number at the begining and then at a rate of 20%
  //
  // Harvesters are created at a rate of 70%

  void robotCreationStep1()
  {
    if (perceiveRobots(ennemy, LAUNCHER) != null)
    {
      if (perceiveRobots(friend, LAUNCHER) == null && energy >= launcherCost)
      {
        newRocketLauncher();
        print("emergency launcher");
        return;
      }
    }

    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].y > 0) && (energy >= KEEP_ENERGY_FOR_EMERGENCY + launcherCost)) {
      // 1st priority = creates rocket launchers 
      if (newRocketLauncher()) brain[5].y--;
    } 
    else if ((brain[5].z > 0) && (energy >= KEEP_ENERGY_FOR_EMERGENCY + explorerCost)) {
      // 2nd priority = creates explorers creates rocket launchers 
      if (newExplorer()) brain[5].z--;
    } 
    else if ((brain[5].x > 0) && (energy >= KEEP_ENERGY_FOR_EMERGENCY + harvesterCost)) {
      // 3rd priority = creates harvesters 
      if (newHarvester()) brain[5].x--;
    } 
    
    else if (energy > KEEP_ENERGY_FOR_EMERGENCY) {
      // if no robot in the pipe and enough energy 
      if ((int)random(10) >= 3)
        // creates a new harvester with 70% chance
        brain[5].x++;
      else if ((int)random(2) == 0)
        // creates a new explorer with 15% chance
        brain[5].z++;
      else
        // creates a new rocket launcher with 15% chance
        brain[5].y++;
    }
    
  }


  //// Step 2
  // 
  //
  //
  //
  //
  void baseBehaviorStep2()
  {
    // handle received messages 
      handleMessages();

      //// ROBOT CREATION
      robotCreation();
      

      // creates new bullets and fafs if the stock is low and enought energy
      manageMissiles();

      // if ennemy rocket launcher in the area of perception
      selfDefense();
  }


  //// Step 3
  // 
  //
  //
  //
  //
  void baseBehaviorStep3()
  {
    // handle received messages 
      handleMessages();

      //// ROBOT CREATION
      robotCreation();
      

      // creates new bullets and fafs if the stock is low and enought energy
      manageMissiles();

      // if ennemy rocket launcher in the area of perception
      selfDefense();
  }

  void baseEmergencyBehavior()
  {
    // handle received messages 
      handleMessages();

      //// ROBOT CREATION
      robotCreationStep1();
      

      // creates new bullets and fafs if the stock is low and enought energy
      manageMissiles();

      // if ennemy rocket launcher in the area of perception
      selfDefense();
  }

  //
  // handleMessage
  // =============
  // > handle messages received since last activation 
  //
  void handleMessages() {
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == ASK_FOR_ENERGY) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0]) {
          // gives the requested amount of energy only if at least 1000 units of energy left after
          giveEnergy(msg.agent, msg.args[0]);
        }
      } else if (msg.type == ASK_FOR_BULLETS) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0] * bulletCost) {
          // gives the requested amount of bullets only if at least 1000 units of energy left after
          giveBullets(msg.agent, msg.args[0]);
        }
      }
    }
    // clear the message queue
    flushMessages();
  }

  void robotCreation()
  {
    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].x > 0) && (energy >= 1000 + harvesterCost)) {
      // 1st priority = creates harvesters 
      if (newHarvester())
        brain[5].x--;
    } else if ((brain[5].y > 0) && (energy >= 1000 + launcherCost)) {
      // 2nd priority = creates rocket launchers 
      if (newRocketLauncher())
        brain[5].y--;
    } else if ((brain[5].z > 0) && (energy >= 1000 + explorerCost)) {
      // 3rd priority = creates explorers 
      if (newExplorer())
        brain[5].z--;
    } else if (energy > 12000) {
      // if no robot in the pipe and enough energy 
      if ((int)random(2) == 0)
        // creates a new harvester with 50% chance
        brain[5].x++;
      else if ((int)random(2) == 0)
        // creates a new rocket launcher with 25% chance
        brain[5].y++;
      else
        // creates a new explorer with 25% chance
        brain[5].z++;
    }
  }

  void manageMissiles()
  {
    if ((bullets < 10) && (energy > 1000)) newBullets(50);
    if ((bullets < 10) && (energy > 1000)) newFafs(10);
  }

  void selfDefense()
  {
    Robot bob = (Robot)minDist(perceiveRobots(ennemy, LAUNCHER));
    if (bob != null) {
      heading = towards(bob);
      // launch a faf if no friend robot on the trajectory...
      if (perceiveRobotsInCone(friend, heading) == null)
        launchFaf(bob);
    }
  }

}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green explorers
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   4.x = (0 = exploration | 1 = go back to base)
//   4.y = (0 = no target | 1 = locked target)
//   0.x / 0.y = coordinates of the target
//   0.z = type of the target
///////////////////////////////////////////////////////////////////////////
class RedExplorer extends Explorer {
  //
  // constructor
  // ===========
  //
  RedExplorer(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    switch ((int) brain[4].x)
    {
      case 0 : explorerEmergencyBehavior(); break;
      case 1 : explorerBehaviorStep1(); break;
      case 2 : explorerBehaviorStep2(); break;
      case 3 : explorerBehaviorStep3(); break;
      default : break;	
    }
  }

  void explorerBehaviorStep1()
  {
    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to base
      brain[3].x = 1;

    // depending on the state of the robot
    if (brain[3].x == 1) {
      // go back to base...
      goBackToBase();
    } else {
      // ...or explore randomly
      randomMove(45);
    }

    // tries to localize ennemy bases
    lookForEnnemyBase();
    // inform harvesters about food sources
    driveHarvesters();
    // inform rocket launchers about targets
    driveRocketLaunchers();

    // clear the message queue
    flushMessages();
  }

  void explorerBehaviorStep2()
  {
    Base bob = (Base)minDist(myBases);
    float dist = distance(bob);

    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to base
      brain[3].x = 1;

    // depending on the state of the robot
    if (brain[3].x == 1) {
      // go back to base...
      goBackToBase();
    } else if(brain[3].x == 0) {
      // Going back to the orbit, for example after a refill
      goBackToOrbit();
    } else if (brain[3].x == 2) {
      // Move in orbit in the trigonometric direction
      moveInOrbit();
    } else {
      // if brain[3].x = 3
      //TargetLock();
    }


    // tries to localize ennemy bases
    lookForEnnemyBase();
    // inform harvesters about food sources
    driveHarvesters();
    // inform rocket launchers about targets
    driveRocketLaunchers();

    // clear the message queue
    flushMessages();
  }

  void goBackToOrbit() {
    // bob is the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one (not all of my bases have been destroyed)
      float dist = distance(bob);

      if (dist < 9 && dist > 0) {
        // if I am not yet in orbit but inside the base radius
        heading = -towards(bob);
        tryToMoveForward();
      } else if (dist == 9) {
        // if I reached the orbit, change the state (orbital state : brain[3].x = 2)
        brain[3].x = 2;
      } else if (dist == 0) {
        // if I am at the center of the base, get away
        randomMove(180);
      } else {
        // if the explorer if out of the base (dist > 9)
        heading = towards(bob);
        tryToMoveForward();
      }
    }
    else {
      // If there aren't any bases left
      brain[4].z = 0;
      brain[3].x = 0;
    }
  }

  void ForwardOrStop() {
    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }

  void moveInOrbit() {
    Base bob = (Base)minDist(myBases);
    heading = towards(bob) + PI/2;
    ForwardOrStop();
  }

  void explorerBehaviorStep3()
  {
    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to base
      brain[3].x = 1;

    // depending on the state of the robot
    if (brain[3].x == 1) {
      // go back to base...
      goBackToBase();
    } else {
      // ...or explore randomly
      randomMove(45);
    }

    // tries to localize ennemy bases
    lookForEnnemyBase();
    // inform harvesters about food sources
    driveHarvesters();
    // inform rocket launchers about targets
    driveRocketLaunchers();

    // clear the message queue
    flushMessages();
  }

  void explorerEmergencyBehavior()
  {

  }

  //
  // setTarget
  // =========
  // > locks a target
  //
  // inputs
  // ------
  // > p = the location of the target
  // > breed = the breed of the target
  //
  void setTarget(PVector p, int breed) {
    brain[0].x = p.x;
    brain[0].y = p.y;
    brain[0].z = breed;
    brain[3].y = 1;
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest base, either to deposit food or to reload energy
  //
  void goBackToBase() {
    // bob is the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one (not all of my bases have been destroyed)
      float dist = distance(bob);

      if (dist <= 2) {
        // if I am next to the base
        if (energy < 500)
          // if my energy is low, I ask for some more
          askForEnergy(bob, 1500 - energy);
        // switch to the exploration state
        brain[3].x = 0;
        // make a half turn
        right(180);
      } else {
        // if still away from the base
        // head towards the base (with some variations)...
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward 
        tryToMoveForward();
      }
    }
  }

  //
  // target
  // ======
  // > checks if a target has been locked
  //
  // output
  // ------
  // true if target locket / false if not
  //
  boolean target() {
    return (brain[3].y == 1);
  }

  //
  // driveHarvesters
  // ===============
  // > tell harvesters if food is localized
  //
  void driveHarvesters() {
    // look for burgers
    Burger zorg = (Burger)oneOf(perceiveBurgers());
    if (zorg != null) {
      // if one is seen, look for a friend harvester
      Harvester harvey = (Harvester)oneOf(perceiveRobots(friend, HARVESTER));
      if (harvey != null)
        // if a harvester is seen, send a message to it with the position of food
        informAboutFood(harvey, zorg.pos);
    }
  }

  //
  // driveRocketLaunchers
  // ====================
  // > tell rocket launchers about potential targets
  //
  void driveRocketLaunchers() {
    // look for an ennemy robot 
    Robot bob = (Robot)oneOf(perceiveRobots(ennemy));
    if (bob != null) {
      // if one is seen, look for a friend rocket launcher
      RocketLauncher rocky = (RocketLauncher)oneOf(perceiveRobots(friend, LAUNCHER));
      if (rocky != null)
        // if a rocket launcher is seen, send a message with the localized ennemy robot
        informAboutTarget(rocky, bob);
    }
  }

  //
  // lookForEnnemyBase
  // =================
  // > try to localize ennemy bases...
  // > ...and to communicate about this to other friend explorers
  //
  void lookForEnnemyBase() {
    // look for an ennemy base
    Base babe = (Base)oneOf(perceiveRobots(ennemy, BASE));
    if (babe != null) {
      // if one is seen, look for a friend explorer
      Explorer explo = (Explorer)oneOf(perceiveRobots(friend, EXPLORER));
      if (explo != null)
        // if one is seen, send a message with the localized ennemy base
        informAboutTarget(explo, babe);
      // look for a friend base
      Base basy = (Base)oneOf(perceiveRobots(friend, BASE));
      if (basy != null)
        // if one is seen, send a message with the localized ennemy base
        informAboutTarget(basy, babe);
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(random(360));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green harvesters
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   4.x = (0 = look for food | 1 = go back to base) 
//   4.y = (0 = no food found | 1 = food found)
//   0.x / 0.y = position of the localized food
///////////////////////////////////////////////////////////////////////////
class RedHarvester extends Harvester {
  //
  // constructor
  // ===========
  //
  RedHarvester(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    switch ((int) brain[4].x)
    {
      case 0 : harvesterEmergencyBehavior(); break;
      case 1 : harvesterBehaviorStep1(); break;
      case 2 : harvesterBehaviorStep2(); break;
      case 3 : harvesterBehaviorStep3(); break;
      default : break;	
    }
  }

  void harvesterBehaviorStep1()
  {
    // handle messages received
    handleMessages();

    // check for the closest burger
    Burger b = (Burger)minDist(perceiveBurgers());
    if ((b != null) && (distance(b) <= 2))
      // if one is found next to the robot, collect it
      takeFood(b);

    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to the base
      brain[3].x = 1;

    // if in "go back" state
    if (brain[3].x == 1) {
      // go back to the base
      goBackToBase();

      // if enough energy and food
      if ((energy > 100) && (carryingFood > 100)) {
        // check for closest base
        Base bob = (Base)minDist(myBases);
        if (bob != null) {
          // if there is one and the harvester is in the sphere of perception of the base
          if (distance(bob) < basePerception)
            // plant one burger as a seed to produce new ones
            plantSeed();
        }
      }
    } else
      // if not in the "go back" state, explore and collect food
      goAndEat();
  }


  void harvesterBehaviorStep2()
  {
    // handle messages received
    handleMessages();

    // check for the closest burger
    Burger b = (Burger)minDist(perceiveBurgers());
    if ((b != null) && (distance(b) <= 2))
      // if one is found next to the robot, collect it
      takeFood(b);

    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to the base
      brain[3].x = 1;

    // if in "go back" state
    if (brain[3].x == 1) {
      // go back to the base
      goBackToBase();

      // if enough energy and food
      if ((energy > 100) && (carryingFood > 100)) {
        // check for closest base
        Base bob = (Base)minDist(myBases);
        if (bob != null) {
          // if there is one and the harvester is in the sphere of perception of the base
          if (distance(bob) < basePerception)
            // plant one burger as a seed to produce new ones
            plantSeed();
        }
      }
    } else
      // if not in the "go back" state, explore and collect food
      goAndEat();
  }


  void harvesterBehaviorStep3()
  {
    // handle messages received
    handleMessages();

    // check for the closest burger
    Burger b = (Burger)minDist(perceiveBurgers());
    if ((b != null) && (distance(b) <= 2))
      // if one is found next to the robot, collect it
      takeFood(b);

    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to the base
      brain[3].x = 1;

    // if in "go back" state
    if (brain[3].x == 1) {
      // go back to the base
      goBackToBase();

      // if enough energy and food
      if ((energy > 100) && (carryingFood > 100)) {
        // check for closest base
        Base bob = (Base)minDist(myBases);
        if (bob != null) {
          // if there is one and the harvester is in the sphere of perception of the base
          if (distance(bob) < basePerception)
            // plant one burger as a seed to produce new ones
            plantSeed();
        }
      }
    } else
      // if not in the "go back" state, explore and collect food
      goAndEat();
  }

  void harvesterEmergencyBehavior()
  {

  }

  //
  // goBackToBase
  // ============
  // > go back to the closest friend base
  //
  void goBackToBase() {
    // look for the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one
      float dist = distance(bob);
      if ((dist > basePerception) && (dist < basePerception + 1))
        // if at the limit of perception of the base, drops a wall (if it carries some)
        dropWall();

      if (dist <= 2) {
        // if next to the base, gives the food to the base
        giveFood(bob, carryingFood);
        if (energy < 500)
          // ask for energy if it lacks some
          askForEnergy(bob, 1500 - energy);
        // go back to "explore and collect" mode
        brain[3].x = 0;
        // make a half turn
        right(180);
      } else {
        // if still away from the base
        // head towards the base (with some variations)...
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    }
  }

  //
  // goAndEat
  // ========
  // > go explore and collect food
  //
  void goAndEat() {
    // look for the closest wall
    Wall wally = (Wall)minDist(perceiveWalls());
    // look for the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      float dist = distance(bob);
      // if wall seen and not at the limit of perception of the base 
      if ((wally != null) && ((dist < basePerception - 1) || (dist > basePerception + 2)))
        // tries to collect the wall
        takeWall(wally);
    }

    // look for the closest burger
    Burger zorg = (Burger)minDist(perceiveBurgers());
    if (zorg != null) {
      // if there is one
      if (distance(zorg) <= 2)
        // if next to it, collect it
        takeFood(zorg);
      else {
        // if away from the burger, head towards it...
        heading = towards(zorg) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    } else if (brain[3].y == 1) {
      // if no burger seen but food localized (thank's to a message received)
      if (distance(brain[0]) > 2) {
        // head towards localized food...
        heading = towards(brain[0]);
        // ...and try to move forward
        tryToMoveForward();
      } else
        // if the food is reached, clear the corresponding flag
        brain[3].y = 0;
    } else {
      // if no food seen and no food localized, explore randomly
      heading += random(-radians(45), radians(45));
      tryToMoveForward();
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(random(360));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }

  //
  // handleMessages
  // ==============
  // > handle messages received
  // > identify the closest localized burger
  //
  void handleMessages() {
    float d = width;
    PVector p = new PVector();

    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      // get next message
      msg = messages.get(i);
      // if "localized food" message
      if (msg.type == INFORM_ABOUT_FOOD) {
        // record the position of the burger
        p.x = msg.args[0];
        p.y = msg.args[1];
        if (distance(p) < d) {
          // if burger closer than closest burger
          // record the position in the brain
          brain[0].x = p.x;
          brain[0].y = p.y;
          // update the distance of the closest burger
          d = distance(p);
          // update the corresponding flag
          brain[3].y = 1;
        }
      }
    }
    // clear the message queue
    flushMessages();
  }
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the green rocket launchers
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   0.x / 0.y = actual position of the target
//   0.z = target locked ? (0 = false, 1 = true)
//   2.x / 2.y = estimated position of the target
//   2.z = breed of the target
//   3.x = current mode
//   4.x = current step
//   4.y = (0 = no target | 1 = localized target)
///////////////////////////////////////////////////////////////////////////
class RedRocketLauncher extends RocketLauncher {
  //
  // constructor
  // ===========
  //
  RedRocketLauncher(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    switch ((int) brain[4].x)
    {
      case 0 : rocketLauncherEmergencyBehavior(); break;
      case 1 : rocketLauncherBehaviorStep1(); break;
      case 2 : rocketLauncherBehaviorStep2(); break;
      case 3 : rocketLauncherBehaviorStep3(); break;
      default : break;	
    }
  }

  boolean hasReceivedMessage(int type)
  {
    Message msg;
    for (int i = 0; i < messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == type) {
        return true;
      }
    }
    return false;
  }

  void rocketLauncherBehaviorStep1()
  {
    // rocket launchers have different modes of action in step 1
    // the mode is determined by brain[3].x
    // 0 -> refill at base mode 
    // 1 -> defend burger mode
    // 2 -> target launcher mode
    // 3 -> target harvester mode
    // 4 -> no current job mode

    determineMode1();

    if (brain[3].x == 0)
    {
      // if in "go back to base" mode
      goBackToBase1();
    }
    else if (brain[3].x == 1)
    {
      // if in defend burger mode
      defendBurger1();
    }
    else if (brain[3].x == 2)
    {
      targetLauncher1();
    }
    else if (brain[3].x == 3)
    {
      targetHarvester1();
    }
    else
    {
      // else explore randomly
      randomMove(45);
    }
    
    /*
    else {
      // try to find a target
      selectTarget();
      // if target identified
      if (target())
        // shoot on the target
        launchBullet(towards(brain[0]));
        
    }
    */
  }

  void determineMode1()
  {
    // if no energy or no bullets
    if ((energy < 100) || (bullets == 0))
      // go back to the base
      brain[3].x = 0;
    
    // if we received the order to attack a rocket launcher, target it
    else if (hasReceivedMessage(13))
    {
      Message msg;
      // for all messages
      for (int i = messages.size()-1; i >= 0; i--) {
        msg = messages.get(i);
        if (msg.type == 13) {
          // target launcher mode
          brain[3].x = 2; 
          // memorize target's position
          brain[2].x = msg.args[0];  
          brain[2].y = msg.args[1];
          brain[2].z = LAUNCHER;
          messages.remove(i);
          break;
        }
      }
    }
    
    // if we see a launcher, target it
    else if (perceiveRobots(ennemy, LAUNCHER) != null)
    {
      brain[3].x = 2;
      RocketLauncher rocky = (RocketLauncher)oneOf(perceiveRobots(ennemy, LAUNCHER));
      brain[2].x = rocky.pos.x;
      brain[2].y = rocky.pos.y;
      brain[2].z = LAUNCHER;
    }
    
    // if we see a harvester, target it
    else if (perceiveRobots(ennemy, HARVESTER) != null)
    {
      brain[3].x = 3;
      Harvester harvey = (Harvester)oneOf(perceiveRobots(ennemy, HARVESTER));
      brain[2].x = harvey.pos.x;
      brain[2].y = harvey.pos.y;
      brain[2].z = HARVESTER;
    }

    // if we see food, target it
    else if (perceiveBurgers() != null)
    {
      Burger burgey = (Burger)oneOf(perceiveBurgers());
      // if it is a wild burger
      if (isBurgerWild(burgey))
      {
        brain[3].x = 1;
        brain[2].x = burgey.pos.x;
        brain[2].y = burgey.pos.y;
        brain[2].z = BURGER;
      }
    }

    // or if we told us about food, target it
    else if (hasReceivedMessage(INFORM_ABOUT_FOOD))
    {
      Message msg;
      // for all messages
      for (int i = messages.size()-1; i >= 0; i--) {
        msg = messages.get(i);
        if (msg.type == INFORM_ABOUT_FOOD) {
          brain[3].x = 1; 
          brain[2].x = msg.args[0];  
          brain[2].y = msg.args[1];
          brain[2].z = BURGER;
          messages.remove(i);
          break;
        }
      }
    }
  }

  void defendBurger1()
  {
    boolean canSeeWildBurger = false;

    Burger burgey = (Burger)oneOf(perceiveBurgers());
    if (burgey != null)
    {
      if (isBurgerWild(burgey))
      {
        canSeeWildBurger = true;
      }
    }

    // if we can't see a wild burger
    if (!canSeeWildBurger)
    {
      // Unlock any locked target
      brain[0].z = 0;

      PVector estimatedPosition = new PVector(brain[2].x, brain[2].y);
      if (distance(estimatedPosition) < launcherPerception)
      {
        // if a wild burger should be there, then our defense job is done
        brain[3].x = 4;
        randomMove(45);
      }
      else
      {
        // else we should get closer to where it should be
        goToPosition(brain[2].x, brain[2].y);
      }
    }

    // if we can see a wild burger, lock the target and then orbit around it
    else
    {
      // if the target is not locked yet
      if (brain[0].z == 0)
      {
        brain[0].z = 1;
        brain[0].x = burgey.pos.x;
        brain[0].y = burgey.pos.y;
      }
      orbitAroundBurger(brain[0].x, brain[0].y, 4.9);
    }
  }

  void targetLauncher1()
  {
    RocketLauncher rocky = (RocketLauncher)minDist(perceiveRobots(ennemy, LAUNCHER));
    // if we can't see a rocket launcher
    if (rocky == null)
    {
      // Unlock any locked target
      brain[0].z = 0;

      PVector estimatedPosition = new PVector(brain[2].x, brain[2].y);
      if (distance(estimatedPosition) < launcherPerception)
      {
        // if the targeted rocket launcher should be there, then our job is done
        brain[3].x = 4;
        randomMove(45);
      }
      else
      {
        // else we should get closer to where it should be
        goToPosition(brain[2].x, brain[2].y);
      }
    }

    // if we see it, lock the target and fire at it
    else
    {
      // if the target is not locked yet, lock it
      if (brain[0].z == 0)
      {
        brain[0].z = 1;
        brain[0].x = rocky.pos.x;
        brain[0].y = rocky.pos.y;
      }
      launchBullet(towards(rocky.pos));
    }
  }

  void targetHarvester1()
  {
    Harvester harvey = (Harvester)minDist(perceiveRobots(ennemy, HARVESTER));
    // if we can't see a harvester
    if (harvey == null)
    {
      // Unlock any locked target
      brain[0].z = 0;

      PVector estimatedPosition = new PVector(brain[2].x, brain[2].y);
      if (distance(estimatedPosition) < launcherPerception)
      {
        // if the targeted harvester should be there, then our job is done
        brain[3].x = 4;
        randomMove(45);
      }
      else
      {
        // else we should get closer to where it should be
        goToPosition(brain[2].x, brain[2].y);
      }
    }

    // if we see it, lock the target, follow it and fire at it
    else
    {
      // if the target is not locked yet, lock it
      if (brain[0].z == 0)
      {
        brain[0].z = 1;
        brain[0].x = harvey.pos.x;
        brain[0].y = harvey.pos.y;
      }

      if (distance(harvey) > 3)
      {
        goToPosition(harvey.pos.x, harvey.pos.y);
      }

      launchBullet(towards(harvey.pos));
    }
  }

  void goToPosition(float x, float y)
  {
    PVector objective = new PVector(x,y);
    heading = towards(objective);
    tryToMoveForward1();
  }

  void orbitAroundBurger(float x, float y, float radius)
  {
    PVector center = new PVector(x,y);
    if (distance(center) >= radius)
    {
      heading = towards(center);
      tryToMoveForward1();
    }
    else
    {
      heading = towards(center);
      right(91 - 360 * launcherSpeed / (TWO_PI * radius));
      tryToMoveForward1();
    }
  }

  // returns true if burgey isn't already in a base
  boolean isBurgerWild(Burger burgey)
  {
    Base tmpBase;
    if (myBases.size() > 0)
    {
      tmpBase = (Base) myBases.get(0);
      if (tmpBase != null)
      {
        if (burgey.distance(tmpBase) <= basePerception) return false;
      }
    }
    if (myBases.size() > 1)
    {
      tmpBase = (Base) myBases.get(1);
      if (tmpBase != null)
      {
        if (burgey.distance(tmpBase) <= basePerception) return false;
      }
    }
    return true;
  }

  void rocketLauncherBehaviorStep2()
  {
    
  }


  void rocketLauncherBehaviorStep3()
  {
    
  }

  void rocketLauncherEmergencyBehavior()
  {

  }

  //
  // selectTarget
  // ============
  // > try to localize a target
  //
  void selectTarget() {
    // look for the closest ennemy robot
    Robot bob = (Robot)minDist(perceiveRobots(ennemy));
    if (bob != null) {
      // if one found, record the position and breed of the target
      brain[0].x = bob.pos.x;
      brain[0].y = bob.pos.y;
      brain[0].z = bob.breed;
      // locks the target
      brain[3].y = 1;
    } else
      // no target found
      brain[3].y = 0;
  }

  //
  // target
  // ======
  // > checks if a target has been locked
  //
  // output
  // ------
  // > true if target locket / false if not
  //
  boolean target() {
    return (brain[3].y == 1);
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest base
  //
  void goBackToBase1() {
    // look for closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one, compute its distance
      float dist = distance(bob);

      if (dist <= 2) {
        // if next to the base
        if (energy < 500)
          // if energy low, ask for some energy
          askForEnergy(bob, 1500 - energy);
        // go back to "exploration" mode
        brain[3].x = 4;
        // make a half turn
        right(180);
      } else {
        // if not next to the base, head towards it... 
        heading = towards(bob);
        //+ random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward1();
      }
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(random(360));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward1() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
    {
      right(random(360));
    }
    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
}
