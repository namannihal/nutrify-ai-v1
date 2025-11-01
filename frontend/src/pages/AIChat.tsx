import React, { useState, useRef, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { ScrollArea } from '@/components/ui/scroll-area';
import { toast } from '@/components/ui/use-toast';
import {
  Sparkles,
  Send,
  Mic,
  Volume2,
  RotateCcw,
  Lightbulb,
  TrendingUp,
  Apple,
  Dumbbell,
  Heart,
  MessageCircle,
} from 'lucide-react';
import { useChatWithAI } from '@/hooks/useApi';

interface Message {
  id: string;
  type: 'user' | 'ai';
  content: string;
  timestamp: Date;
  explanation?: string;
  suggestions?: string[];
  category?: 'nutrition' | 'fitness' | 'motivation' | 'general';
}

export default function AIChat() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const scrollAreaRef = useRef<HTMLDivElement>(null);
  const chatMutation = useChatWithAI();

  const quickActions = [
    { icon: TrendingUp, label: "Analyze my progress", category: "analysis" },
    { icon: Apple, label: "Meal suggestions", category: "nutrition" },
    { icon: Dumbbell, label: "Workout help", category: "fitness" },
    { icon: Heart, label: "Motivation boost", category: "motivation" },
  ];

  const aiPersonality = {
    name: "Coach Alex",
    avatar: "/avatars/ai-coach.jpg",
    specialties: ["Nutrition", "Fitness", "Motivation", "Progress Analysis"]
  };

  useEffect(() => {
    if (scrollAreaRef.current) {
      scrollAreaRef.current.scrollTop = scrollAreaRef.current.scrollHeight;
    }
  }, [messages]);

  const handleSendMessage = async (content: string) => {
    if (!content.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      type: 'user',
      content: content.trim(),
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue('');

    try {
      const response = await chatMutation.mutateAsync(content);
      
      const aiMessage: Message = {
        id: Date.now().toString(),
        type: 'ai',
        content: response.response,
        timestamp: new Date(),
        explanation: response.explanation,
        category: 'general',
      };
      
      setMessages(prev => [...prev, aiMessage]);
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to get AI response. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleVoiceInput = () => {
    toast({
      title: "Voice input",
      description: "Voice input feature coming soon!",
    });
  };

  const handleTextToSpeech = (message: Message) => {
    toast({
      title: "Text-to-speech",
      description: "Text-to-speech feature coming soon!",
    });
  };

  const clearChat = () => {
    setMessages([]);
    toast({
      title: "Chat cleared",
      description: "Starting a fresh conversation",
    });
  };

  const MessageBubble = ({ message }: { message: Message }) => (
    <div className={`flex gap-3 ${message.type === 'user' ? 'justify-end' : 'justify-start'}`}>
      {message.type === 'ai' && (
        <Avatar className="w-8 h-8">
          <AvatarImage src={aiPersonality.avatar} alt={aiPersonality.name} />
          <AvatarFallback className="bg-gradient-to-br from-blue-600 to-indigo-600 text-white text-xs">
            AI
          </AvatarFallback>
        </Avatar>
      )}
      
      <div className={`max-w-[80%] ${message.type === 'user' ? 'order-first' : ''}`}>
        <div className={`rounded-lg p-3 ${
          message.type === 'user' 
            ? 'bg-primary text-primary-foreground ml-auto' 
            : 'bg-muted'
        }`}>
          <p className="text-sm">{message.content}</p>
          
          {message.type === 'ai' && (
            <div className="flex items-center gap-2 mt-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleTextToSpeech(message)}
                className="h-6 px-2"
              >
                <Volume2 className="h-3 w-3" />
              </Button>
              <span className="text-xs text-muted-foreground">
                {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
          )}
        </div>

        {message.explanation && (
          <div className="mt-2 p-2 bg-blue-50 rounded-lg border-l-2 border-blue-200">
            <div className="flex items-start gap-2">
              <Lightbulb className="h-3 w-3 text-blue-600 mt-0.5" />
              <div>
                <p className="text-xs font-medium text-blue-900">Why this recommendation:</p>
                <p className="text-xs text-blue-800">{message.explanation}</p>
              </div>
            </div>
          </div>
        )}

        {message.suggestions && message.suggestions.length > 0 && (
          <div className="mt-2 space-y-1">
            <p className="text-xs text-muted-foreground">Suggested follow-ups:</p>
            <div className="flex flex-wrap gap-1">
              {message.suggestions.map((suggestion, index) => (
                <Button
                  key={index}
                  variant="outline"
                  size="sm"
                  className="h-6 text-xs"
                  onClick={() => handleSendMessage(suggestion)}
                >
                  {suggestion}
                </Button>
              ))}
            </div>
          </div>
        )}
      </div>

      {message.type === 'user' && (
        <Avatar className="w-8 h-8">
          <AvatarImage src="/avatars/demo-user.jpg" alt="You" />
          <AvatarFallback>You</AvatarFallback>
        </Avatar>
      )}
    </div>
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">AI Coach Chat</h1>
          <p className="text-muted-foreground">
            Get personalized guidance and insights from your AI health companion
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="secondary" className="gap-1">
            <Sparkles className="h-3 w-3" />
            AI Active
          </Badge>
          <Button variant="outline" onClick={clearChat}>
            <RotateCcw className="h-4 w-4 mr-2" />
            Clear Chat
          </Button>
        </div>
      </div>

      {/* AI Coach Info */}
      <Card className="border-blue-200 bg-gradient-to-r from-blue-50 to-indigo-50">
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <Avatar className="w-12 h-12">
              <AvatarImage src={aiPersonality.avatar} alt={aiPersonality.name} />
              <AvatarFallback className="bg-gradient-to-br from-blue-600 to-indigo-600 text-white">
                AI
              </AvatarFallback>
            </Avatar>
            <div className="flex-1">
              <h3 className="font-semibold text-blue-900">{aiPersonality.name}</h3>
              <p className="text-sm text-blue-800">Your personal AI health coach</p>
              <div className="flex flex-wrap gap-1 mt-1">
                {aiPersonality.specialties.map((specialty) => (
                  <Badge key={specialty} variant="secondary" className="text-xs">
                    {specialty}
                  </Badge>
                ))}
              </div>
            </div>
            <div className="text-right">
              <div className="flex items-center gap-1 text-green-600">
                <div className="w-2 h-2 rounded-full bg-green-500"></div>
                <span className="text-xs font-medium">Online</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Quick Actions</CardTitle>
          <CardDescription>Get instant help with common requests</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {quickActions.map((action, index) => (
              <Button
                key={index}
                variant="outline"
                className="h-auto p-3 flex flex-col gap-2"
                onClick={() => handleSendMessage(action.label)}
              >
                <action.icon className="h-5 w-5" />
                <span className="text-xs">{action.label}</span>
              </Button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Chat Interface */}
      <Card className="flex-1">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MessageCircle className="h-5 w-5" />
            Conversation
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <ScrollArea className="h-96 p-4" ref={scrollAreaRef}>
            <div className="space-y-4">
              {messages.map((message) => (
                <MessageBubble key={message.id} message={message} />
              ))}
              
              {chatMutation.isPending && (
                <div className="flex gap-3">
                  <Avatar className="w-8 h-8">
                    <AvatarFallback className="bg-gradient-to-br from-blue-600 to-indigo-600 text-white text-xs">
                      AI
                    </AvatarFallback>
                  </Avatar>
                  <div className="bg-muted rounded-lg p-3">
                    <div className="flex items-center gap-2">
                      <div className="flex space-x-1">
                        <div className="w-2 h-2 bg-muted-foreground rounded-full animate-bounce [animation-delay:-0.3s]"></div>
                        <div className="w-2 h-2 bg-muted-foreground rounded-full animate-bounce [animation-delay:-0.15s]"></div>
                        <div className="w-2 h-2 bg-muted-foreground rounded-full animate-bounce"></div>
                      </div>
                      <span className="text-xs text-muted-foreground">AI is thinking...</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </ScrollArea>
          
          {/* Input Area */}
          <div className="border-t p-4">
            <div className="flex gap-2">
              <div className="flex-1 relative">
                <Input
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  placeholder="Ask me anything about your health and fitness..."
                  onKeyPress={(e) => e.key === 'Enter' && handleSendMessage(inputValue)}
                  className="pr-12"
                />
                <Button
                  variant="ghost"
                  size="sm"
                  className="absolute right-1 top-1/2 -translate-y-1/2 h-8 w-8 p-0"
                  onClick={handleVoiceInput}
                >
                  <Mic className="h-4 w-4" />
                </Button>
              </div>
              <Button 
                onClick={() => handleSendMessage(inputValue)}
                disabled={!inputValue.trim() || chatMutation.isPending}
              >
                <Send className="h-4 w-4" />
              </Button>
            </div>
            <p className="text-xs text-muted-foreground mt-2">
              💡 Tip: Ask about your progress, request meal suggestions, or get workout modifications
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}