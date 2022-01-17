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
  static final int MY_CUSTOM_MSG = 5;
  static final int DEFEND_AT_XY = 12;
  static final int TARGET_LAUNCHER_AT_XY = 13;
  static final int ENNEMY_BASE_AT_XY = 14;
  static final int PLANTED_A_BURGER = 15;
  static final int TARGET_ENNEMY_AT_XY = 16;
  static final int CURRENT_PHASE = 17;

  // STRATEGY PARAMETERS
  static final int KEEP_ENERGY_FOR_CREATION = 8000;

  // Step 1 specifics
  static final int WILD_BURGER_TO_FARM = 250;
  static final int BASIC_ENERGY_NEED = 2000;
  static final int MAXIMUM_OBSERVERS = 10;

  // Step 2 specifics
  static final int HARVESTERS_TO_CREATE = 50;
  static final float BURGER_RATIO_FOR_BASE = 20.0/100.0;
  static final int ENERGY_FOR_ARMAGGEDON = 1000000;
  static final int LAUNCHER_FOR_ARMAGGEDON = 50;

  // Step 3 specifics
  static final int LAUNCHER_TO_CREATE = 100;


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
    brain[5].x = 5;
    brain[5].y = 2;
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
    // 1: Step 1 specifics:  x -> burgers at home  y -> observers produced 
    // 2: Step 2 specifics: 
    // 3: Step 3 specifics:  x -> harvesters produced   y -> observers produced 
    // 4:
    // 5: Robot creation :  x -> Harvester   y -> Rocket Launcher   z -> Explorer
    // 6: x / y -> Coordinates of ennemy base 1   z -> do we know it yet ?
    // 7: x / y -> Coordinates of ennemy base 2   z -> do we know it yet ?
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
      //if (enemyRobots.size() >= 5) brain[9].y = 1;
    }

    // if no emergency
    if (brain[9].y == 0)
    {
      // we are in step 1 by default
      brain[9].x = 1;

      // go to step 2 if we collected enough wild burgers and we know enemy bases
      if (brain[1].x >= WILD_BURGER_TO_FARM && brain[7].z == 1)
      {
        brain[9].x = 2;
      } 

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
        if (brain[9].x == 2){
          // required initialization for step 2
          friend.brain[3].x = 0;
        }
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

    // make sure all explorers know the current amount of ennemy bases known
    warnExplorersAboutEnemyBases();

    // tell the harvesters if there are burgers to get
    warnHarvestersAboutBurgers();

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

      // if the message is a request for energy
      if (msg.type == ASK_FOR_ENERGY) 
      {
       
        if (energy > 1000 + msg.args[0]) {
          // gives the requested amount of energy only if at least 1000 units of energy left after
          giveEnergy(msg.agent, msg.args[0]);
        }
      } 

      // if the message is a request for bullets
      else if (msg.type == ASK_FOR_BULLETS) 
      {
        if (energy > 1000 + msg.args[0] * bulletCost) {
          // gives the requested amount of bullets only if at least 1000 units of energy left after
          giveBullets(msg.agent, msg.args[0]);
        }
      }

      // if the message is a base position
      else if (msg.type == ENNEMY_BASE_AT_XY)
      {
        // if we don't know base 1
        if (brain[6].z == 0)
        {
          // save the ennemy base as base 1
          brain[6].x = msg.args[0];
          brain[6].y = msg.args[1];
          brain[6].z = 1;
        }
        // if we don't know base 2
        else if (brain[7].z == 0)
        {
          // if the ennemy base isn't base 1, save it as base 2
          if (msg.args[0] != brain[6].x || msg.args[1] != brain[6].y)
          {
            brain[7].x = msg.args[0];
            brain[7].y = msg.args[1];
            brain[7].z = 1;
          }
        }
      }

      // if the message is a burger plantation
      else if (msg.type == PLANTED_A_BURGER)
      {
        brain[1].x ++;
      }
      
    }
    // clear the message queue
    flushMessages();
  }

  void warnExplorersAboutEnemyBases()
  {
    ArrayList<Robot> friendlyExplorers = perceiveRobots(friend, EXPLORER);
    if (friendlyExplorers != null)
    {
      for (Robot friend : friendlyExplorers)
      {
        if (friend.brain[3].x != 3)
        {
          if (brain[7].z == 1)
          {
            if (friend.brain[1].z == 2) friend.brain[1].z = 3;
            else friend.brain[1].z = 2;
          } 
          else if (brain[6].z == 1)
          {
            friend.brain[1].x = brain[6].x;
            friend.brain[1].y = brain[6].y;
            friend.brain[1].z = 1;
          } 
          else friend.brain[1].z = 0;
        }
        
      }
    }
  }

  void warnHarvestersAboutBurgers()
  {
    Burger zorg = (Burger)oneOf(perceiveBurgers());
    if (zorg != null) {
      ArrayList<Harvester> harvesters = perceiveRobots(friend, HARVESTER);
      if (harvesters != null)
      {
        for (Harvester harvey : harvesters)
        {
          informAboutFood(harvey, zorg.pos);
        }
      }
    }
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
        return;
      }
    }

    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].y > 0) && (energy >= KEEP_ENERGY_FOR_CREATION + launcherCost)) {
      // 1st priority = creates rocket launchers 
      if (newRocketLauncher()) brain[5].y--;
    } 
    else if ((brain[5].z > 0) && (energy >= KEEP_ENERGY_FOR_CREATION + explorerCost)) {
      // 2nd priority = creates explorers creates rocket launchers 
      if (newExplorer())
      {
        brain[5].z--;
        brain[1].y++;
      } 
    } 
    else if ((brain[5].x > 0) && (energy >= KEEP_ENERGY_FOR_CREATION + harvesterCost)) {
      // 3rd priority = creates harvesters 
      if (newHarvester()) brain[5].x--;
    } 
    else if (energy > KEEP_ENERGY_FOR_CREATION) {
      // if no robot in the pipe and enough energy 
      if ((int)random(10) >= 3)
        // creates a new harvester with 70% chance
        brain[5].x++;
      else if ((int)random(3) == 0 && brain[1].y < MAXIMUM_OBSERVERS/2)
        // creates a new explorer with 10% chance
        brain[5].z++;
      else
        // creates a new rocket launcher with 20% chance
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
    ArrayList<Robot> launcherlist = perceiveRobots(friend,LAUNCHER);
    ArrayList<Robot> harvesterlist = perceiveRobots(friend,HARVESTER);
    ArrayList<Robot> explorerlist = perceiveRobots(friend,EXPLORER);
    // handle received messages 
      handleMessages();

      //// ROBOT CREATION
      robotCreation2(launcherlist,harvesterlist, explorerlist);

      //// Sending rocket launchers their positions
      if (launcherlist != null){
        for (int i = 0 ; i < launcherlist.size() ; i++){
          float[] position = new float[2];
          position[0] = pos.x + 8.5 * cos(radians(i * 2 * PI / launcherlist.size()));
          position[1] = pos.y + 8.5 * sin(radians(i * 2 * PI / launcherlist.size()));
          sendMessage(launcherlist.get(i), 4 , position);
        }
      }
      // creates new bullets and fafs if the stock is low and enought energy
      manageMissiles();

      // if ennemy rocket launcher in the area of perception
      selfDefense();
  }

  void robotCreation2(ArrayList<Robot> launch, ArrayList<Robot> harv, ArrayList<Robot> explo)
  {
    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].x > 0) && (energy >= 1000 + harvesterCost)) {
      // 1st priority = creates harvesters 
      if (newHarvester())
        brain[5].x--;
        print("Harvester created");
    } else if ((brain[5].y > 0) && (energy >= 1000 + launcherCost)) {
      // 2nd priority = creates rocket launchers 
      if (newRocketLauncher())
        brain[5].y--;
        print("launcher created \n");
    } else if ((brain[5].z > 0) && (energy >= 6000 + explorerCost)) {
      // 3rd priority = creates explorers 
      if (newExplorer())
        brain[5].z--;
        print("explorer created \n");
    } else if (energy > 10000) {
      // if there aren't enough robots to harvest inside the base
      if (brain[5].x == 0 && harv.size() < 6)
        brain[5].x++;

      // creates a new launcher before explorers if their number is too low (as long as one explorer is here)
      else if (brain[5].y == 0 && launch.size() < 5 && explo.size() > 0)
        brain[5].y++;
      // once the minimum amount of launchers is here, we can get to a good amount of explorers
      else if (brain[5].z == 0 && explo.size() < 4)
        brain[5].z++;

      // finally, prepare for war by stacking launchers
      else if (brain[5].y == 0)
        brain[5].y++;
    }
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

      // tell the harvesters if there are burgers to get
      warnHarvestersAboutBurgers();

      // tell the rocket launchers about the base
      tellLaunchersAboutBase();

      //// ROBOT CREATION
      robotCreationStep3();

      // creates new bullets and fafs if the stock is low and enought energy
      manageMissiles3();

      // if ennemy rocket launcher in the area of perception
      selfDefense();
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

  void robotCreationStep3()
  {
    
    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].y > 0) && (energy >= KEEP_ENERGY_FOR_CREATION + launcherCost)) {
      // 1st priority = creates rocket launchers 
      if (newRocketLauncher()) brain[5].y--;
    } 
    else if ((brain[5].z > 0) && (energy >= KEEP_ENERGY_FOR_CREATION + explorerCost)) {
      // 2nd priority = creates explorers creates rocket launchers 
      if (newExplorer()) brain[5].z--;
    } 
    else if ((brain[5].x > 0) && (energy >= KEEP_ENERGY_FOR_CREATION + harvesterCost)) {
      // 3rd priority = creates harvesters 
      if (newHarvester()) brain[5].x--;
    } 
    else if (energy > KEEP_ENERGY_FOR_CREATION) {
      // if no robot in the pipe and enough energy 
      if ((int)random(10) <= 85)
        // creates a new rocket launcher with 90% chance
        brain[5].x++;
      else if ((int)random(2) > 0 && brain[3].y < 10)
      {
        // creates a new explorer with 5% chance
        brain[5].y++;
        brain[3].y++;
      }
        
      else if (brain[3].x < 10)
      {
        // creates a new harvester with 5% chance
        brain[5].z++;
        brain[3].x++;
      }
        
    }
  }

  void tellLaunchersAboutBase()
  {
    ArrayList<RocketLauncher> friendlyLaunchers = perceiveRobots(friend, LAUNCHER);
    if (friendlyLaunchers != null)
    {
      for (RocketLauncher launchy : friendlyLaunchers)
      {
        launchy.brain[1].x = brain[6].x;
        launchy.brain[1].y = brain[6].y;
        launchy.brain[1].z = 0;
        launchy.brain[2].x = brain[7].x;
        launchy.brain[2].y = brain[7].y;
        launchy.brain[2].z = 0;
      }
    }
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

  void manageMissiles3()
  {
    if ((bullets < 50) && (energy > 2000)) newBullets(100);
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
//   1.x / 1.y = coordinate of ennemy base 1
//   1.z = ( 0 = No known base | 1 = 1 known base | 2 = all bases known)
//   2.x = last time i heard about phase
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

    tellAboutCurrentPhase();

    switch ((int) brain[4].x)
    {
      case 0 : explorerEmergencyBehavior(); break;
      case 1 : explorerBehaviorStep1(); break;
      case 2 : explorerBehaviorStep2(); break;
      case 3 : explorerBehaviorStep3(); break;
      default : break;	
    }
  }

  void tellAboutCurrentPhase()
  {
    Message msg;
    // for all messages
    for (int i = messages.size()-1; i >= 0; i--) {
      msg = messages.get(i);
      if (msg.type == 17) {
        if ( msg.args[1] < brain[2].x && msg.args[0] != brain[4].x)
        {
          brain[4].x = msg.args[0];
          brain[2].x = 0;

          ArrayList<Robot> allrobs = perceiveRobots(friend);
          if (allrobs != null)
          {
            for (Robot rob : allrobs)
            {
              rob.brain[4].x = brain[4].x;
            }
          }
        }
        
        messages.remove(i);
        break;
      }
    }
  }

  void explorerBehaviorStep1()
  {
    // rocket launchers have different modes of action in step 1
    // the mode is determined by brain[3].x
    // 0 -> refill at base mode 
    // 1 -> exploration mode
    // 2 -> seek harvesters mode
    // 3 -> tell bases about ennemy base mode

    determineMode1();

    if (brain[3].x == 0) 
    {
      goBackToBase1();
    }
    else if (brain[3].x == 1) 
    {
      heading += random(-radians(45), radians(45));
      moveForwardButFleeLaunchers();
    }
    else if (brain[3].x == 2) 
    {
      // Orbit around the burger and tell them about the food then go back to explore mode
      orbitAroundBurgerButFlee(brain[0].x, brain[0].y, detectionRange - 0.3);
      // inform harvesters about food sources
      driveHarvesters();
    }
    else if (brain[3].x == 3) 
    {
      tellAboutEnnemyBase();
    }

    // inform rocket launchers about targets
    driveRocketLaunchers();

    // clear the message queue
    flushMessages();
  }

  void determineMode1()
  {
    // if food to deposit or too few energy
    if (((carryingFood > 200) || (energy < 100)) && brain[3].x != 3)
      // time to go back to base
      brain[3].x = 0;

    // go tell about base if we see one
    lookForEnnemyBase1();

    if ((brain[3].x != 0 || brain[3].x != 3) && brain[1].z >= 2)
    {
      // if we see food and it is a wild burger
      Burger zorg = (Burger)oneOf(perceiveBurgers());
      if (zorg != null) {
        if (isBurgerWild(zorg))
        {
          //target it and switch to seek harvester mode
          brain[0].x = zorg.pos.x;
          brain[0].y = zorg.pos.y;
          brain[3].x = 2;
          }
      }

      else 
      {
        brain[3].x = 1;
      }
    }

    
  }

  //
  // goBackToBase1
  // ============
  // > go back to the closest base, either to deposit food or to reload energy
  //
  void goBackToBase1() {
    // bob is the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one (not all of my bases have been destroyed)
      float dist = distance(bob);

      // if I am next to the base
      if (dist <= 2) 
      {
        // if my energy is low, I ask for some more
        if (energy < 500) askForEnergy(bob, 1500 - energy);

        // if carrying food, give it to the base
        if (carryingFood > 0) giveFood(bob, carryingFood);
        
        // switch to the exploration state
        brain[3].x = 1;
        // make a half turn
        right(180);
      } 
      else 
      {
        // if still away from the base
        // head towards the base (with some variations)...
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward 
        moveForwardButFleeLaunchers();
      }
    }
  }

  //
  // lookForEnnemyBase1
  // =================
  // > try to localize ennemy bases...
  // > ...and to communicate about this to other friend explorers
  //
  void lookForEnnemyBase1() {

    // if we don't know about all bases and we aren't in tell about base mode
    if (brain[1].z < 3 && brain[3].x !=3)
    {
      // look for an ennemy base
      Base babe = (Base)oneOf(perceiveRobots(ennemy, BASE));
      // if we see one
      if (babe != null) {
        // if we don't know any base
        if (brain[1].z == 0)
        {
          brain[1].x = babe.pos.x;
          brain[1].y = babe.pos.y;
          brain[3].x = 3; // go back to base to tell it
          brain[3].y = 1; // tell it to base 1
        }
        // if we already know one base
        else if (brain[1].z == 1)
        {
          // if this base is a new one
          if (brain[1].x != babe.pos.x || brain[1].y != babe.pos.y)
          {
            brain[1].x = babe.pos.x;
            brain[1].y = babe.pos.y;
            brain[3].x = 3; // go back to base to tell it
            brain[3].y = 1; // tell it to base 1
          }
        }
      }
    }
  }

  void tellAboutEnnemyBase() 
  {
    Base tmpBase;

    // if we should tell it to base 1
    if (brain[3].y == 1)
    {
      // if we have 1 base
      if (myBases.size() > 0)
      {
        tmpBase = (Base) myBases.get(0);
        if (tmpBase != null)
        {
          if (distance(tmpBase) <= detectionRange)
          {
            // tell the base about it if close enough
            float[] args = new float[2];
            args[0] = brain[1].x;
            args[1] = brain[1].y;
            sendMessage(tmpBase, 14, args);
            brain[3].y = 2; // then go tell it to base 2
          }
          else
          {
            heading = towards(tmpBase);
            moveForwardButFleeLaunchers();
          }
        }
      }
      else brain[3].x = 1;
    }
    
    // if we should tell it to base 2
    if (brain[3].y == 2)
    {
      // if we have an other base
      if (myBases.size() > 1)
      {
        tmpBase = (Base) myBases.get(1);
        if (tmpBase != null)
        {
          if (distance(tmpBase) <= 2)
          {
            // tell the base about it if close enough
            float[] args = new float[2];
            args[0] = brain[1].x;
            args[1] = brain[1].y;
            sendMessage(tmpBase, 14, args);
            brain[3].x = 1; // then go back to exploration
            brain[3].y = 1; 
          }
          else
          {
            heading = towards(tmpBase);
            moveForwardButFleeLaunchers();
          }
        }
      }
      else brain[3].x = 1;
    }
  }

  void orbitAroundBurgerButFlee(float x, float y, float radius)
  {
    PVector center = new PVector(x,y);
    if (distance(center) >= radius)
    {
      heading = towards(center);
      moveForwardButFleeLaunchers();
    }
    else
    {
      heading = towards(center);
      right(91 - 360 * launcherSpeed / (TWO_PI * radius));
      moveForwardButFleeLaunchers();
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

  void moveForwardButFleeLaunchers()
  {
    
    PVector wantedDirection = new PVector(patchSize * cos(heading), patchSize * sin(heading), 0);
    
    PVector resultDirection = wantedDirection.copy();
    resultDirection.normalize();

    float FMAX = 5;
    float FMIN = 1;
    
    ArrayList<RocketLauncher> ennemyLaunchers = perceiveRobots(ennemy, LAUNCHER);
    if (ennemyLaunchers != null)
    {
      for (RocketLauncher rocky : ennemyLaunchers)
      {
        PVector ennemyForce = pos.copy();
        ennemyForce.sub(rocky.pos);
        ennemyForce.normalize();
        // the force of the vector is an interpolation using the distance from the explorer to the ennemy launcher
        float d = distance(rocky);
        float power = FMIN + (d - launcherPerception) * (FMAX - FMIN) / (explorerPerception - launcherPerception);
        ennemyForce.mult(power);
        resultDirection.add(ennemyForce);
      }
    }
    
    PVector finalPosition = pos.copy();
    resultDirection.normalize();
    finalPosition.add(resultDirection);

    heading = towards(finalPosition);
    tryToMoveForward();
  }


void explorerBehaviorStep2()
  {
    Base bob = (Base)minDist(myBases);
    driveRocketLaunchers();

    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to base
      brain[3].x = 1;

    // depending on the state of the robot
    if (brain[3].x == 1) {
      // go back to base...
      goBackToBase();
    } else if(brain[3].x == 0 || (brain[3].x == 2 && perceiveRobots(ennemy) == null)) {
      // Going back to the orbit (==0) OR moving in orbit (==2) (only if no ennemies are detected)
      orbitAroundPointExp(bob.pos.x, bob.pos.y, 9.5);
    } else if (brain[3].x == 2 && perceiveRobots(ennemy) != null){
      // only robots in orbital state can target lock an ennemy. They do it only if the target isn't already locked by
      // another explorer
      for (int j = 0 ; j < perceiveRobots(ennemy).size() ; j++) {
        // we check all ennemies to see if an ally already locked them
        if(!alreadyLocked((Robot)perceiveRobots(ennemy).get(j))) {
          // if we find an ennemy robot that isn't locked already, we go in lock mode and save the ennemy's id and coordinates
          brain[2].z = ((Robot)perceiveRobots(ennemy).get(j)).who;
          brain[2].x = ((Robot)perceiveRobots(ennemy).get(j)).pos.x;
          brain[2].y = ((Robot)perceiveRobots(ennemy).get(j)).pos.y;
          brain[3].x = 3;
          break;
        }
      }
      // if we get there, it means that we didn't lock any target
      orbitAroundPointExp(bob.pos.x, bob.pos.y, 9.5);
      
    }
    if (brain[3].x == 3) {
      boolean found = false;
      // lock the target if he's still there
      if (perceiveRobots(ennemy) != null){
        for (int j = 0 ; j < perceiveRobots(ennemy).size() ; j++) {
          if (brain[2].z < ((Robot)perceiveRobots(ennemy).get(j)).who + 0.1 && brain[2].z > ((Robot)perceiveRobots(ennemy).get(j)).who - 0.1){
            // if the target is still there, update the coordinates
            brain[2].x = ((Robot)perceiveRobots(ennemy).get(j)).pos.x;
            brain[2].y = ((Robot)perceiveRobots(ennemy).get(j)).pos.y;
            found = true;
            targetLock();
            break;
          }
        }
        if (!found){
          // if we didn't find our target in the list of perceived robots, meaning he left
          // reset brain[2] info
          brain[2].z = 0;
        
          // if the target left, go back to either orbital state or "going back to orbit" state
          if (distance(bob.pos) < 9 || distance(bob.pos) > 9.9){
            brain[3].x = 0;
          }
          else {
            brain[3].x = 2;
          }
        }
      }
      // if we didn't see any robots (meaning we also didn't see the one we targeted)
      else {
        // reset brain[2] info
        brain[2].z = 0;
        
        // if the target left, go back to either orbital state or "going back to orbit" state
        if (distance(bob.pos) < 9 || distance(bob.pos) > 9.9){
          brain[3].x = 0;
        }
        else {
          brain[3].x = 2;
        }
      }
    }

    // inform harvesters about food sources
    driveHarvesters();

    // clear the message queue
    flushMessages();
  }

  //
  // Check in nearby friendly explorers have alrady locked the robot bob
  //
  boolean alreadyLocked(Robot bob){
    if (perceiveRobots(friend, EXPLORER) == null){
      return false;
    }
    if (perceiveRobots(ennemy) == null){
      print("something wrong in explorer conditions");
      return true;
    }
    else {
      ArrayList<Robot> friendlist = perceiveRobots(friend, EXPLORER);
      for (int i = 0 ; i < friendlist.size() ; i++){
        // check if a friendly explorer already locked the ennemy in sight (by checking if the saved id corresponds)
        float ennemy_id = friendlist.get(i).brain[2].z;
        if (bob.who < ennemy_id + 0.1 && bob.who > ennemy_id -0.1){
          return true;
        }
      }
    }
    return false;
  }
  
  
  //
  // Tries to move forward, if it's not possible, doesn't move
  //
  void forwardOrStop() {
    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
  
  
  //
  // Orbits around a point (explorer version), at a given radius. If it is not near the radius, move towards it
  //
  void orbitAroundPointExp(float x, float y, float radius)
  {
    PVector center = new PVector(x,y);
    if (distance(center) > radius + 0.5)
    {
      heading = towards(center);
      tryToMoveForward();
    }
    else if (distance(center) < radius - 0.5) {
      heading = towards(center) + PI;
      tryToMoveForward();
    }
    else
    {
      heading = towards(center);
      right(91 - 360 * speed / (TWO_PI * radius));
      tryToMoveForward();
      // brain[3].x = 2 means that the explorer is in orbit, so if it was in the way back to the orbit now it's over
      // (if the tryToMoveForward function made the explorer go out
      // of orbit range, it will go back to it, so we don't change its state)
      if (distance(center) > radius - 0.5 && distance(center) < radius + 0.5) {
        brain[3].x = 2;
      }
    }
  }
  
  
  //
  // Stays on the orbit but tries to be between the base and the detected ennemy (in order to guide 
  // nearby friendly rocketlauncher)
  // Same functionning as orbitAroundPointExp except it will either go clockwise or anti clockwise in order to go between
  // the base and the ennemy robot
  void targetLock(){
    Base bob = (Base)minDist(myBases);
    PVector center = new PVector(bob.pos.x,bob.pos.y);
    
    if (distance(center) > 9.9)
    {
      heading = towards(center);
      tryToMoveForward();
    }
    else if (distance(center) < 9) {
      heading = towards(center) + PI;
      tryToMoveForward();
    }
    else
    {
      // we will compute the angle between base-explorer and base-ennemy to see which direction should the explorer go
      // we need first to compute the two angles relatively to the x axis (base-explorer with x axis and base ennemy with x axis)
      // atan2 uses the center of the map so we need to do a translation
      
      // angle of the explorer
      float deltaX_explo = pos.x + (width/2 - center.x);
      float deltaY_explo = pos.y + (height/2 - center.y);
      
      float angle_explo = atan2(deltaX_explo, deltaY_explo);
      
      // angle of the ennemy
      float deltaX_enn = brain[2].x + (width/2 - center.x);
      float deltaY_enn = brain[2].y + (height/2 - center.y);
      
      float angle_enn = atan2(deltaX_enn, deltaY_enn);
      
      
      heading = towards(center);
      
      if (angle_explo > angle_enn){
        right(91 - 360 * speed / (TWO_PI * 9.5));
        tryToMoveForward();
      } else {
        left(91 - 360 * speed / (TWO_PI * 9.5));
        tryToMoveForward();
      }
      // if the explorer goes out of orbit, it loses the lock state, so we also reset its brain[2]
      if (distance(center) < 9 || distance(center) > 9.9) {
        brain[3].x = 0;
        brain[2].z = 0;
      }
    }
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
      heading += random(-radians(45), radians(45));
      tryToMoveForward();
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
// map of the brain in Step 1
//   3.x = (0 = look for food | 1 = go back to base) 
//   3.y = (0 = no food found | 1 = food found)
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
    if (((carryingFood > 1000) || (energy < 100)) && brain[3].x != 2)
      // time to go back to the base
      brain[3].x = 1;

    // if in "go back" state
    if (brain[3].x == 1) {
      // go back to the base
      goBackToBase1();

      // if enough energy and food
      if ((energy > 100) && (carryingFood > 100)) {
        // check for closest base
        Base bob = (Base)minDist(myBases);
        if (bob != null) {
          // if there is one and the harvester is in the sphere of perception of the base
          if (distance(bob) < basePerception)
            // plant one burger as a seed to produce new ones
            brain[3].x = 2; // switch to plant mode
        }
      }
    } 
    else if (brain[3].x == 2)
    {
      optimizedPlantation();
    }
    // if not in the "go back" state, explore and collect food
    else goAndEat();
  }

  void optimizedPlantation()
  {
    Base bob = (Base)minDist(myBases);
    if (bob != null)
    {
      //if the base has enough energy, plant seeds
      if (bob.energy > RedBase.BASIC_ENERGY_NEED && distance(bob) > 2)
      {
        if (carryingFood > 100)
        {
          heading = towards(bob);
          right(random(60,70) - 360 * launcherSpeed / (TWO_PI * basePerception));
          tryToMoveForward();
          plantSeed();
          float[] args = new float[0];
          sendMessage(bob, RedBase.PLANTED_A_BURGER, args);
        }
        else brain[3].x = 0;
      }

      //else head to the base to give it the food
      else
      {
        if (distance(bob) <= 2) {
          if (energy < 500)
            // ask for energy if it lacks some
            askForEnergy(bob, 1500 - energy);
          // go back to "explore and collect" mode
          brain[3].x = 0;
        } 
        else
        {
          // else head towards the base
          heading = towards(bob) + random(-radians(20), radians(20));
          tryToMoveForward();
        }
      }
      
    }
    else brain[3].x = 0;
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
    if (brain[3].x == 1) 
    {
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
    if (brain[3].x == 1) 
    {
      // go back to the base
      goBackToBase();

      // if enough energy and food
      if ((energy > 100) && (carryingFood > 100)) 
      {
        // check for closest base
        Base bob = (Base)minDist(myBases);
        if (bob != null) 
        {
          // if there is one and the harvester is in the sphere of perception of the base
          if (distance(bob) < basePerception)
            // plant one burger as a seed to produce new ones
            plantSeed();
        }
      }
    }
    else 
    {
      goAndEat3();
    }
  }

  void goAndEat3()
  {
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
    } 
    else if (brain[3].y == 1) 
    {
      // if no burger seen but food localized (thank's to a message received)
      if (distance(brain[0]) > 2) 
      {
        // head towards localized food...
        heading = towards(brain[0]);
        // ...and try to move forward
        tryToMoveForward();
      } 
      // if the food is reached, clear the corresponding flag
      else brain[3].y = 0;
    } 
    else 
    {
      bob = (Base)minDist(myBases);
      if (bob != null) {
        if (distance(bob) > basePerception) heading = towards(bob);
      }
      else heading += random(-radians(45), radians(45));
      tryToMoveForward();
    }
  }

  void harvesterEmergencyBehavior()
  {

  }

  //
  // goBackToBase
  // ============
  // > go back to the closest friend base
  //
  void goBackToBase1() {
    // look for the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one
      float dist = distance(bob);
      if ((dist > basePerception) && (dist < basePerception + 2))
        // if at the limit of perception of the base, drops a wall (if it carries some)
        dropWall();
      // if still away from the base
      // head towards the base (with some variations)...
      heading = towards(bob) + random(-radians(20), radians(20));
      // ...and try to move forward
      tryToMoveForward();
    }
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
      } 
      else {
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
// map of the brain in step 1
//   0.x / 0.y = actual position of the target
//   0.z = target locked ? (0 = false, 1 = true)
//   2.x / 2.y = estimated position of the target
//   2.z = breed of the target
//   3.x = current mode
//   4.x = current step
//   4.y = (0 = no target | 1 = localized target)
///////////////////////////////////////////////////////////////////////////
// map of the brain in step 3
//   0.x / 0.y = position of the target
//   0.z = target breed
//   1.x / 1.y = position of base 1   1.z = base destroyed ?
//   2.x / 2.y = position of base 2   2.z = base destroyed ?
//   3.x = current mode   3.z = target lock
//   4.x = current step
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
      goBackToBaseLauncher();
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
      heading += random(-radians(45), radians(45));
      tryToMoveForward();
    }
    
    // TODO : launch fafs at explorers
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
    
    // if we told us about a target, target it
    else if (hasReceivedMessage(INFORM_ABOUT_TARGET))
    {
      Message msg;
      // for all messages
      for (int i = messages.size()-1; i >= 0; i--) {
        msg = messages.get(i);
        if (msg.type == INFORM_ABOUT_TARGET) {
          
          if (msg.args[2] == LAUNCHER)
          {
            brain[3].x = 2; 
            brain[2].z = LAUNCHER;
          } 
          else if (msg.args[2] == HARVESTER)
          {
            brain[3].x = 3; 
            brain[2].z = HARVESTER;
          }
          // memorize target's position
          brain[2].x = msg.args[0];  
          brain[2].y = msg.args[1];
          
          messages.remove(i);
          break;
        }
      }
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
        heading += random(-radians(45), radians(45));
        tryToMoveForward();
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
        heading += random(-radians(45), radians(45));
        tryToMoveForward();
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
        heading += random(-radians(45), radians(45));
        tryToMoveForward();
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
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward1();
      }
    }
  }

  //
  // goes back to base, but launcher need bullets too so this function can also ask for bullets
  //
  void goBackToBaseLauncher() {
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

        if (bullets == 0) {
          askForBullets(bob, 1000);
        }
        // go back to "exploration" mode
        brain[3].x = 4;
        // make a half turn
        right(180);
      } else {
        // if not next to the base, head towards it... 
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward1();
      }
    }
  }

  //
  // same function but puts the robot in a different state at the end
  //
  void goBackToBaseLauncher2() {
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

        if (bullets == 0) {
          askForBullets(bob, 1000);
        }
        // go back to "exploration" mode
        brain[3].x = 1;
        // make a half turn
        right(180);
      } else {
        // if not next to the base, head towards it... 
        heading = towards(bob) + random(-radians(20), radians(20));
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

  void rocketLauncherBehaviorStep2()
  {
    // rocket launchers have different modes of action in step 1
    // the mode is determined by brain[3].x
    // 0 -> refill at base mode 
    // 1 -> staying or going in standby position
    // 2 -> target launcher mode (without getting too far)
    // 3 -> target harvester mode (without getting too far)
    // 4 -> no current job mode

    // the robot keeps in memory the position the base ordered
    if (ReceivedMessageFromBase(4) != null){
      brain[1].x = ReceivedMessageFromBase(4).x;
      brain[1].y = ReceivedMessageFromBase(4).y;
    }

    // closest base
    Base bob = (Base)minDist(myBases);

    determineMode12();
    if (distance(bob) > 9.5 && !(brain[3].x == 0)){
      // no matter the action taken (except going back to base), goes to standby state if he is too far
      brain[3].x = 1; 
    }

    if (brain[3].x == 0)
    {
      // if in "go back to base" mode
      goBackToBaseLauncher2();
    }
    else if (brain[3].x == 1)
    {
      // stays around the position he stores in brain[1], or goes to it
      goToPosition(brain[1].x,brain[1].y);
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
      // this case isn't supposed to happen, but just in case
      goToPosition(brain[1].x,brain[1].y);
    }
  }

  // 
  // check if we received a message from base
  //
  PVector ReceivedMessageFromBase(int type)
  {
    Message msg;
    PVector msg_needed = new PVector(0.0,0.0);
    for (int i = 0; i < messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == type && msg.agent == BASE) {
        msg_needed.x = msg.args[0];
        msg_needed.y = msg.args[1];
        return msg_needed;
      }
    }
    return null;
  }

  void determineMode12()
  {
    // basic state
    brain[3].x = 1;
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
    
    // if we toldus about a target, target it
    else if (hasReceivedMessage(INFORM_ABOUT_TARGET))
    {
      Message msg;
      // for all messages
      for (int i = messages.size()-1; i >= 0; i--) {
        msg = messages.get(i);
        if (msg.type == INFORM_ABOUT_TARGET) {
          
          if (msg.args[2] == LAUNCHER)
          {
            brain[3].x = 2; 
            brain[2].z = LAUNCHER;
          } 
          else if (msg.args[2] == HARVESTER)
          {
            brain[3].x = 3; 
            brain[2].z = HARVESTER;
          }
          // memorize target's position
          brain[2].x = msg.args[0];  
          brain[2].y = msg.args[1];
          
          messages.remove(i);
          break;
        }
      }
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
  }


  void rocketLauncherBehaviorStep3()
  {
    // rocket launchers have different modes of action in step 3
    // the mode is determined by brain[3].x
    // 0 -> refill at base mode 
    // 1 -> fire at target mode

    determineMode3();

    if (brain[3].x == 0)
    {
      // if in "go back to base" mode
      goBackToBase3();
    }
    else if (brain[3].x == 1)
    {
      choseTarget3();
      fireAtTarget3();
    }
    else
    {
      // else explore randomly
      heading += random(-radians(45), radians(45));
      tryToMoveForward();
    }
  }

  void determineMode3()
  {
    if (bullets == 0 || energy < 150)
    {
      brain[3].x = 0;
    }
    else brain[3].x = 1;
  }
  void choseTarget3()
  {
    if (hasReceivedMessage(13))
    {
      Message msg;
      // for all messages
      for (int i = messages.size()-1; i >= 0; i--) {
        msg = messages.get(i);
        if (msg.type == 13) {
          // memorize target's position
          brain[0].x = msg.args[0];  
          brain[0].y = msg.args[1];
          brain[0].z = LAUNCHER;
          brain[3].z = 0;
          messages.remove(i);
          break;
        }
      }
    }

    // if we see a launcher, target it
    else if (perceiveRobots(ennemy, LAUNCHER) != null )
    {
      RocketLauncher rocky = (RocketLauncher)oneOf(perceiveRobots(ennemy, LAUNCHER));
      brain[0].x = rocky.pos.x;
      brain[0].y = rocky.pos.y;
      brain[0].z = LAUNCHER;
      brain[3].z = 0;
    }

    // else target a base
    else
    {
      // if the 1st base is still alive
      if (brain[1].z == 0)
      {
        brain[0].x = brain[1].x;
        brain[0].y = brain[1].y;
        brain[0].z = BASE;
        brain[3].z = 0;
      }
      else if (brain[2].z == 0)
      {
        brain[0].x = brain[2].x;
        brain[0].y = brain[2].y;
        brain[0].z = BASE;
        brain[3].z = 0;
      }
    }
  }
  void goBackToBase3()
  {
    // look for closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one, compute its distance
      float dist = distance(bob);
      // if next to the base
      if (dist <= 2) {
        // if energy low, ask for some energy
        if (energy < 4000) askForEnergy(bob, 4000);
        if (bullets < 50) askForBullets(bob, 100 - bullets);
      } 
      else {
        // if not next to the base, head towards it... 
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    }
  }

  void fireAtTarget3()
  {

    PVector targetPos = new PVector(brain[0].x, brain[0].y);
    if (brain[0].z == BASE)
    {
      Base babe = (Base)minDist(perceiveRobots(ennemy, BASE));
      if (babe != null)
      {
        if (distance(targetPos) < launcherPerception)
        {
          brain[1].z = 1;
          brain[3].z = 0;
        }
        else brain[3].z = 1;
      }
    }
    else
    {
      RocketLauncher ly = (RocketLauncher)minDist(perceiveRobots(ennemy, LAUNCHER));
      if (ly != null)
      {
        brain[0].x = ly.pos.x;
        brain[0].y = ly.pos.y;
        brain[3].z = 1;
      }
    }
    
    if (brain[3].z == 1)
    {
      launchBullet(towards(brain[0]));
    }
    else
    {
      heading = towards(targetPos) + random(-radians(20), radians(20));
      tryToMoveForward();
    }


  }

  void rocketLauncherEmergencyBehavior()
  {

  }
}
