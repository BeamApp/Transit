package com.example.transit.example;

import android.content.Context;
import android.graphics.Color;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.LinearLayout;
import android.widget.TextView;

public class ChatArrayAdapter extends ArrayAdapter<ChatMessage> {

    public ChatArrayAdapter(Context context, int textViewResourceId) {
        super(context, textViewResourceId);
    }

    @Override
    public View getView(int position, View row, ViewGroup parent) {
        if (row == null) {
            LayoutInflater inflater = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            row = inflater.inflate(R.layout.fragment_chatmessage, parent, false);
        }

        ChatMessage chatMessage = getItem(position);
        LinearLayout wrapper = (LinearLayout) row.findViewById(R.id.chatmessage_message_wrapper);
        TextView messageView = (TextView) row.findViewById(R.id.chatmessage_message);
        messageView.setText(chatMessage.getMessage());
        
        
        if (chatMessage.isFromUser()) {
            wrapper.setGravity(Gravity.RIGHT);
            messageView.setTextColor(Color.RED);
        } else {
            wrapper.setGravity(Gravity.LEFT);
            messageView.setTextColor(Color.BLUE); 
        }
        
        return row;
    }

}
