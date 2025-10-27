# Building Low Code Agents with Google Cloud's Conversational Agents

## Overview
In this lab, you'll deploy a pre-built low code generative AI agents using Google Cloud's Conversational Agents tool. We'll cover the essential concepts and walk you through the initial steps to get your first agent up and running.

With Conversational Agents, AI Agents can be created in just a few steps. For today's lab, we will be importing a Pre-Built Agent so that you can see how it works and play around with it
### Step 1: Go to Conversational Agents page
- Head over to the Conversational Agents console by clicking the following link: 
https://conversational-agents.cloud.google.com
- Select your project from the project menu
- Next, select **Use prebuilt agents**

- In the next page (shown below), select the **Travel** agent (You might have to scroll all the way down).
> [!NOTE]  
> You might see multiple travel-themed agents. Make sure to select the agent that is named **Travel**.

![Select Travel page](./images/select_travel.png)

- Click on **Import Agent**
![Import Agent page](./images/import_agent.png)

- For the settings, give your Agent a name **(e.g. John Travel)**
- Leave everything else as default and click on **Create**
![Pre-built Agent Settings](./images/prebuilt_agent_settings.png)

- Next, in the left panel click on **Tools**
- Click into **places_search** tool.
![Tools Page](./images/tools_page.png)

- Scroll down to **Schema**
- Under Server URL, replace the URL with:
```bash
https://travel-places-search-288715243473.us-central1.run.app
```
- Once done, click **Save**
![Replace URL](./images/replace_server_url.png)

- Repeat this for the other tools - remember to always click **Save** after you edit!
  
| Tool Name         | URL |
| :---------------- | :------ |
| places_search     | https://travel-places-search-288715243473.us-central1.run.app    |
| hotel_booking     | https://travel-book-hotel-288715243473.us-central1.run.app       |
| hotel_search      | https://travel-places-search-288715243473.us-central1.run.app    |
| get_user_profile  | https://travel-get-user-profile-288715243473.us-central1.run.app |

- Once you're done, you are ready to test your travel agent! 
- Head back to Playbooks and select **Travel Steering**
- Click on the **Chat** icon at the top to toggle open the simulator
![Toggle open chat](./images/toggle_chat.png)

### Ask away!
You can ask for recommendations, more information about certain places and also try to get it to book a hotel for you (of course it'll be a simulated booking, not an actual one!)
- Here are some as starters:
    - Beach vacation in Phuket
    - Hotels near the beach in Phuket
    - Hotels in Sentosa

For example: When asking about certain places you should be able to see that the ```places_search``` tool gets triggered to do a Google Maps API call and retrieve places related to your query. And that's how you get your agent to interact with other systems to enrich it.

![Tools Trigger](./images/trigger_tool.png)

### [Optional] Deploy the Cloud Run functions
In this lab, you're using Cloud Run functions that have already been deployed for you and maintained by the organizing team. To take it a step further, you can also try your hand at deploying the functions onto Cloud Run. To do so, you may refer to the instructions in the Travel prebuilt agent official documentation under [tools setup](https://cloud.google.com/dialogflow/cx/docs/concept/playbook/prebuilt/travel#tool-setup). 

Happy building ⚒️!